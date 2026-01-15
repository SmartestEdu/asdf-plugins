#!/usr/bin/env bash

# shfmt - Shell script formatter
# Repository: https://github.com/mvdan/sh

set -euo pipefail

readonly REPO="mvdan/sh"

list_all_versions() {
  list_github_versions "$REPO" | sort_versions | tr '\n' ' '
}

get_download_url() {
  local version="$1"
  local os
  local arch

  os="$(get_os)"
  arch="$(get_arch)"

  # Map to shfmt naming conventions
  case "$arch" in
    amd64) arch="amd64" ;;
    arm64) arch="arm64" ;;
    386) arch="386" ;;
    arm) arch="arm" ;;
    *) error_exit "shfmt does not support architecture: $arch" ;;
  esac

  echo "https://github.com/${REPO}/releases/download/v${version}/shfmt_v${version}_${os}_${arch}"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "shfmt only supports version installs, not ref installs"
  fi

  local url
  url="$(get_download_url "$version")"

  mkdir -p "$download_path/bin"
  # shfmt is distributed as a bare binary
  download_file "$url" "$download_path/bin/shfmt"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  mkdir -p "$install_path/bin"
  install_binary "$download_path/bin/shfmt" "$install_path/bin/shfmt" "shfmt"
}
