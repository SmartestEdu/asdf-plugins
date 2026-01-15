#!/usr/bin/env bash

# jq - Command-line JSON processor
# Repository: https://github.com/jqlang/jq

set -euo pipefail

readonly REPO="jqlang/jq"

list_all_versions() {
  list_github_versions "$REPO" | sort_versions | tr '\n' ' '
}

get_download_url() {
  local version="$1"
  local os
  local arch

  os="$(get_os)"
  arch="$(get_arch)"

  # Map to jq's naming conventions
  case "$os" in
    darwin) os="macos" ;;
    linux) os="linux" ;;
  esac

  case "$arch" in
    amd64) arch="amd64" ;;
    arm64) arch="arm64" ;;
    *) error_exit "jq does not support architecture: $arch" ;;
  esac

  echo "https://github.com/${REPO}/releases/download/jq-${version}/jq-${os}-${arch}"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "jq only supports version installs, not ref installs"
  fi

  local url
  url="$(get_download_url "$version")"

  mkdir -p "$download_path/bin"
  download_file "$url" "$download_path/bin/jq"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  mkdir -p "$install_path/bin"
  install_binary "$download_path/bin/jq" "$install_path/bin/jq" "jq"
}
