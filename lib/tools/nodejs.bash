#!/usr/bin/env bash

# nodejs - JavaScript runtime built on Chrome's V8 JavaScript engine
# Repository: https://github.com/nodejs/node

set -euo pipefail

readonly REPO="https://nodejs.org/dist"

list_all_versions() {
  local versions
  versions="$(curl_wrapper -fsSL "${REPO}/index.json" | grep -oE '"version":"v[^"]+"' | sed 's/"version":"v//;s/"//' | sort_versions)"
  echo "$versions" | tr '\n' ' '
}

get_download_url() {
  local version="$1"
  local os
  local arch

  os="$(get_os)"
  arch="$(get_arch)"

  # Map to Node.js naming conventions
  case "$os" in
    darwin) os="darwin" ;;
    linux) os="linux" ;;
  esac

  case "$arch" in
    amd64) arch="x64" ;;
    arm64) arch="arm64" ;;
    *) error_exit "nodejs does not support architecture: $arch" ;;
  esac

  echo "${REPO}/v${version}/node-v${version}-${os}-${arch}.tar.gz"
}

# Check if custom build configuration is requested via environment variables.
# When any of these are set, Node.js will be compiled from source using node-build
# instead of installing a precompiled binary.
# See: https://github.com/nodenv/node-build?tab=readme-ov-file#custom-build-configuration
needs_custom_build() {
  [ -n "${NODE_CONFIGURE_OPTS:-}" ] || [ -n "${NODE_MAKE_OPTS:-}" ] || [ -n "${NODE_MAKE_INSTALL_OPTS:-}" ]
}

# Ensure node-build (https://github.com/nodenv/node-build) is available for
# source compilation. Shallow-clones it on first use.
# Returns the path to the node-build executable.
ensure_node_build() {
  local node_build_dir="${ASDF_DATA_DIR:-$HOME/.asdf}/tmp/node-build"
  local node_build_cmd="${node_build_dir}/bin/node-build"

  if [ -x "$node_build_cmd" ]; then
    echo "$node_build_cmd"
    return 0
  fi

  echo "Installing node-build for source compilation..." >&2
  rm -rf "$node_build_dir"
  git clone --depth 1 https://github.com/nodenv/node-build.git "$node_build_dir" \
    || error_exit "Failed to clone node-build. Ensure git is available."

  if [ ! -x "$node_build_cmd" ]; then
    error_exit "node-build installation failed: ${node_build_cmd} not found"
  fi

  echo "$node_build_cmd"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "nodejs only supports version installs, not ref installs"
  fi

  # When custom build options are set, skip binary download;
  # node-build will download source and compile during install.
  if needs_custom_build; then
    echo "Custom build options detected; skipping binary download (node-build will compile from source)"
    mkdir -p "$download_path"
    return 0
  fi

  local url
  url="$(get_download_url "$version")"

  mkdir -p "$download_path"
  download_file "$url" "$download_path/nodejs.tar.gz"
  extract_tar_gz "$download_path/nodejs.tar.gz" "$download_path"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  if needs_custom_build; then
    install_from_source "$version" "$install_path"
  else
    install_from_binary "$version" "$download_path" "$install_path"
  fi

  # Enable corepack if it exists (available in Node.js 16.10+)
  if [ -f "$install_path/bin/corepack" ]; then
    echo "Enabling corepack..."
    "$install_path/bin/corepack" enable --install-directory "$install_path/bin" || echo "Warning: Failed to enable corepack"
  fi

  # Install default npm packages if configured
  install_default_npm_packages "$install_path"

  echo "Installed nodejs to $install_path"
}

install_from_source() {
  local version="$1"
  local install_path="$2"

  local node_build_cmd
  node_build_cmd="$(ensure_node_build)"

  echo "Compiling Node.js ${version} from source with custom build options..."
  [ -n "${NODE_CONFIGURE_OPTS:-}" ] && echo "  NODE_CONFIGURE_OPTS: ${NODE_CONFIGURE_OPTS}"
  [ -n "${NODE_MAKE_OPTS:-}" ] && echo "  NODE_MAKE_OPTS: ${NODE_MAKE_OPTS}"
  [ -n "${NODE_MAKE_INSTALL_OPTS:-}" ] && echo "  NODE_MAKE_INSTALL_OPTS: ${NODE_MAKE_INSTALL_OPTS}"
  echo "This may take a while..."

  # node-build natively respects these environment variables:
  #   NODE_CONFIGURE_OPTS    - additional ./configure options (e.g. --experimental-enable-pointer-compression)
  #   NODE_MAKE_OPTS         - additional make options
  #   NODE_MAKE_INSTALL_OPTS - additional make install options
  # The --compile flag forces compilation from source (skips precompiled binary check).
  "$node_build_cmd" --compile "$version" "$install_path" \
    || error_exit "node-build failed to compile Node.js ${version}. Check build output above for details."
}

install_from_binary() {
  local version="$1"
  local download_path="$2"
  local install_path="$3"

  local os
  os="$(get_os)"
  local arch
  arch="$(get_arch)"

  case "$arch" in
    amd64) arch="x64" ;;
    arm64) arch="arm64" ;;
  esac

  # Copy the extracted directory contents
  cp -r "$download_path/node-v${version}-${os}-${arch}"/* "$install_path/"
}

install_default_npm_packages() {
  local install_path="$1"

  # Resolve packages file location
  local packages_file="${ASDF_NPM_DEFAULT_PACKAGES_FILE:-$HOME/.default-npm-packages}"

  # Return silently if file doesn't exist (optional feature)
  if [ ! -f "$packages_file" ]; then
    return 0
  fi

  # Check if npm exists
  if [ ! -f "$install_path/bin/npm" ]; then
    echo "Warning: npm not found in Node.js installation, skipping default packages"
    return 0
  fi

  echo "Installing default npm packages from $packages_file..."

  local line
  local package_spec
  local failed_packages=()

  while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines
    [ -z "$line" ] && continue

    # Skip comments (lines starting with #)
    [[ "$line" =~ ^[[:space:]]*# ]] && continue

    # Trim leading/trailing whitespace
    package_spec="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    # Skip if empty after trimming
    [ -z "$package_spec" ] && continue

    # Install package with flags preserved
    echo "  Installing: $package_spec"
    if PATH="$install_path/bin:$PATH" "$install_path/bin/npm" install -g $package_spec > /dev/null 2>&1; then
      echo "    Success: $package_spec"
    else
      echo "    Warning: Failed to install $package_spec"
      failed_packages+=("$package_spec")
    fi
  done < "$packages_file"

  # Summary
  if [ ${#failed_packages[@]} -eq 0 ]; then
    echo "Successfully installed all default npm packages"
  else
    echo "Warning: Failed to install ${#failed_packages[@]} package(s): ${failed_packages[*]}"
  fi

  return 0  # Always return success to not fail Node.js installation
}
