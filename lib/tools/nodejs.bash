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

  echo "Installed nodejs to $install_path"
}
