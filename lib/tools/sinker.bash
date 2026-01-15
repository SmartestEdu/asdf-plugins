#!/usr/bin/env bash

# sinker - Tool to sync container images between registries
# Repository: https://github.com/plexsystems/sinker

set -euo pipefail

readonly REPO="plexsystems/sinker"

list_all_versions() {
  list_github_versions "$REPO" | sort_versions | tr '\n' ' '
}

get_download_url() {
  local version="$1"
  local os
  local arch

  os="$(get_os)"
  arch="$(get_arch)"

  # Map to sinker's naming conventions
  case "$os" in
    darwin) os="Darwin" ;;
    linux) os="Linux" ;;
  esac

  case "$arch" in
    amd64) arch="x86_64" ;;
    arm64) arch="arm64" ;;
    *) error_exit "sinker does not support architecture: $arch" ;;
  esac

  echo "https://github.com/${REPO}/releases/download/v${version}/sinker_${version}_${os}_${arch}.tar.gz"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "sinker only supports version installs, not ref installs"
  fi

  local url
  url="$(get_download_url "$version")"

  mkdir -p "$download_path/bin"
  download_file "$url" "$download_path/sinker.tar.gz"
  extract_tar_gz "$download_path/sinker.tar.gz" "$download_path/bin"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  mkdir -p "$install_path/bin"
  install_binary "$download_path/bin/sinker" "$install_path/bin/sinker" "sinker"
}
