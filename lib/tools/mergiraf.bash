#!/usr/bin/env bash

# mergiraf - A syntax-aware merge driver for git
# Repository: https://codeberg.org/mergiraf/mergiraf

set -euo pipefail

readonly GIT_REPO="https://codeberg.org/mergiraf/mergiraf.git"

list_all_versions() {
  list_git_versions "$GIT_REPO" '^v[0-9]' | sort_versions | tr '\n' ' '
}

get_target() {
  local os arch

  os="$(get_os)"
  arch="$(get_arch)"

  case "${os}_${arch}" in
    linux_amd64)  echo "x86_64-unknown-linux-gnu" ;;
    linux_arm64)  echo "aarch64-unknown-linux-gnu" ;;
    darwin_amd64) echo "x86_64-apple-darwin" ;;
    darwin_arm64) echo "aarch64-apple-darwin" ;;
    *) error_exit "mergiraf does not support platform: ${os}_${arch}" ;;
  esac
}

get_download_url() {
  local version="$1"
  local target
  target="$(get_target)"

  echo "https://codeberg.org/mergiraf/mergiraf/releases/download/v${version}/mergiraf_${target}.tar.gz"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "mergiraf only supports version installs, not ref installs"
  fi

  local url
  url="$(get_download_url "$version")"

  mkdir -p "$download_path"
  download_file "$url" "$download_path/mergiraf.tar.gz"
  extract_tar_gz "$download_path/mergiraf.tar.gz" "$download_path"

  mkdir -p "$download_path/bin"
  mv "$download_path/mergiraf" "$download_path/bin/"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  mkdir -p "$install_path/bin"
  install_binary "$download_path/bin/mergiraf" "$install_path/bin/mergiraf" "mergiraf"
}
