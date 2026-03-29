#!/usr/bin/env bash

# rtk - Rust Token Killer: high-performance CLI proxy that reduces LLM token consumption
# Repository: https://github.com/rtk-ai/rtk

set -euo pipefail

readonly REPO="rtk-ai/rtk"

list_all_versions() {
  # Filter to only stable releases (v-prefixed tags), excluding dev/rc pre-releases
  list_github_versions "$REPO" '^v[0-9]' | sort_versions | tr '\n' ' '
}

get_target() {
  local os arch

  os="$(get_os)"
  arch="$(get_arch)"

  case "${os}_${arch}" in
    linux_amd64)  echo "x86_64-unknown-linux-musl" ;;
    linux_arm64)  echo "aarch64-unknown-linux-gnu" ;;
    darwin_amd64) echo "x86_64-apple-darwin" ;;
    darwin_arm64) echo "aarch64-apple-darwin" ;;
    *) error_exit "rtk does not support platform: ${os}_${arch}" ;;
  esac
}

get_download_url() {
  local version="$1"
  local target
  target="$(get_target)"

  echo "https://github.com/${REPO}/releases/download/v${version}/rtk-${target}.tar.gz"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "rtk only supports version installs, not ref installs"
  fi

  local url
  url="$(get_download_url "$version")"

  mkdir -p "$download_path"
  download_file "$url" "$download_path/rtk.tar.gz"
  extract_tar_gz "$download_path/rtk.tar.gz" "$download_path"

  # The tarball contains the 'rtk' binary at root
  mkdir -p "$download_path/bin"
  mv "$download_path/rtk" "$download_path/bin/"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  mkdir -p "$install_path/bin"
  install_binary "$download_path/bin/rtk" "$install_path/bin/rtk" "rtk"
}
