#!/usr/bin/env bash

# acli - Atlassian CLI
# Documentation: https://developer.atlassian.com/cloud/acli/

set -euo pipefail

list_all_versions() {
  # Atlassian only provides "latest" downloads without versioned archives.
  # We list "current" as the only version - users always get whatever
  # Atlassian is currently serving. Check actual version with: acli --version
  echo "current"
}

get_download_url() {
  local version="$1"
  local os
  local arch

  os="$(get_os)"
  arch="$(get_arch)"

  # Only amd64 and arm64 are supported
  case "$arch" in
    amd64 | arm64) ;;
    *) error_exit "acli does not support architecture: $arch" ;;
  esac

  # URL pattern: https://acli.atlassian.com/{os}/latest/acli_{os}_{arch}.tar.gz
  echo "https://acli.atlassian.com/${os}/latest/acli_${os}_${arch}.tar.gz"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "acli only supports version installs, not ref installs"
  fi

  local url
  url="$(get_download_url "$version")"

  mkdir -p "$download_path"
  download_file "$url" "$download_path/acli.tar.gz"
  extract_tar_gz "$download_path/acli.tar.gz" "$download_path"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  # Find the acli binary - it's inside a directory like acli_X.Y.Z_os_arch/
  local binary
  binary=$(find "$download_path" -name "acli" -type f -executable 2>/dev/null | head -n1)

  if [ -z "$binary" ]; then
    error_exit "Could not find acli binary in extracted archive"
  fi

  mkdir -p "$install_path/bin"
  install_binary "$binary" "$install_path/bin/acli" "acli"
}
