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

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "nodejs only supports version installs, not ref installs"
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

  # Enable corepack if it exists (available in Node.js 16.10+)
  if [ -f "$install_path/bin/corepack" ]; then
    echo "Enabling corepack..."
    "$install_path/bin/corepack" enable --install-directory "$install_path/bin" || echo "Warning: Failed to enable corepack"
  fi

  # Install default npm packages if configured
  install_default_npm_packages "$install_path"

  echo "Installed nodejs to $install_path"
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
