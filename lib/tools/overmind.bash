#!/usr/bin/env bash

# overmind - Process manager for Procfile-based applications
# Repository: https://github.com/DarthSim/overmind

set -euo pipefail

readonly REPO="DarthSim/overmind"

list_all_versions() {
  list_github_versions "$REPO" | sort_versions | tr '\n' ' '
}

get_download_url() {
  local version="$1"
  local os
  local arch

  os="$(get_os)"
  arch="$(get_arch)"

  # Map to overmind's naming conventions
  case "$arch" in
    amd64) arch="amd64" ;;
    arm64) arch="arm64" ;;
    *) error_exit "overmind does not support architecture: $arch" ;;
  esac

  echo "https://github.com/${REPO}/releases/download/v${version}/overmind-v${version}-${os}-${arch}.gz"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "overmind only supports version installs, not ref installs"
  fi

  local url
  url="$(get_download_url "$version")"

  mkdir -p "$download_path/bin"
  download_file "$url" "$download_path/overmind.gz"
  gunzip "$download_path/overmind.gz"
  mv "$download_path/overmind" "$download_path/bin/"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  mkdir -p "$install_path/bin"
  install_binary "$download_path/bin/overmind" "$install_path/bin/overmind" "overmind"
}
