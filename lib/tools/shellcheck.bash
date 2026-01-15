#!/usr/bin/env bash

# shellcheck - Shell script analysis tool
# Repository: https://github.com/koalaman/shellcheck

set -euo pipefail

readonly REPO="koalaman/shellcheck"

list_all_versions() {
  list_github_versions "$REPO" | sort_versions | tr '\n' ' '
}

get_download_url() {
  local version="$1"
  local os
  local arch

  os="$(get_os)"
  arch="$(get_arch)"

  # Map to shellcheck naming conventions
  case "$arch" in
    amd64) arch="x86_64" ;;
    arm64) arch="aarch64" ;;
    *) error_exit "shellcheck does not support architecture: $arch" ;;
  esac

  echo "https://github.com/${REPO}/releases/download/v${version}/shellcheck-v${version}.${os}.${arch}.tar.xz"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "shellcheck only supports version installs, not ref installs"
  fi

  local url
  url="$(get_download_url "$version")"

  mkdir -p "$download_path"
  download_file "$url" "$download_path/shellcheck.tar.xz"

  # Extract tar.xz
  echo "Extracting shellcheck..."
  tar -xJf "$download_path/shellcheck.tar.xz" -C "$download_path" || error_exit "Failed to extract shellcheck"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  mkdir -p "$install_path/bin"
  install_binary "$download_path/shellcheck-v${version}/shellcheck" "$install_path/bin/shellcheck" "shellcheck"
}
