#!/usr/bin/env bash

# yq - YAML processor
# Repository: https://github.com/mikefarah/yq

set -euo pipefail

readonly REPO="mikefarah/yq"

list_all_versions() {
  list_github_versions "$REPO" | sort_versions | tr '\n' ' '
}

get_download_url() {
  local version="$1"
  local os
  local arch

  os="$(get_os)"
  arch="$(get_arch)"

  # Map to yq's naming conventions
  case "$os" in
    darwin) os="darwin" ;;
    linux) os="linux" ;;
  esac

  case "$arch" in
    amd64) arch="amd64" ;;
    arm64) arch="arm64" ;;
    386) arch="386" ;;
    *) error_exit "yq does not support architecture: $arch" ;;
  esac

  echo "https://github.com/${REPO}/releases/download/v${version}/yq_${os}_${arch}"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "yq only supports version installs, not ref installs"
  fi

  local url
  url="$(get_download_url "$version")"

  mkdir -p "$download_path/bin"
  download_file "$url" "$download_path/bin/yq"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  mkdir -p "$install_path/bin"
  install_binary "$download_path/bin/yq" "$install_path/bin/yq" "yq"
}
