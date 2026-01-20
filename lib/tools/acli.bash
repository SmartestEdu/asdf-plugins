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

  # URL pattern: https://acli.atlassian.com/{os}/latest/acli_{os}_{arch}/acli
  echo "https://acli.atlassian.com/${os}/latest/acli_${os}_${arch}/acli"
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

  mkdir -p "$download_path/bin"
  download_file "$url" "$download_path/bin/acli"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  mkdir -p "$install_path/bin"
  install_binary "$download_path/bin/acli" "$install_path/bin/acli" "acli"
}
