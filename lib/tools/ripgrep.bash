#!/usr/bin/env bash

# ripgrep (rg) - Fast recursive grep alternative
# Repository: https://github.com/BurntSushi/ripgrep

set -euo pipefail

readonly REPO="BurntSushi/ripgrep"

list_all_versions() {
  list_github_versions "$REPO" | sort_versions | tr '\n' ' '
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
    *) error_exit "ripgrep does not support platform: ${os}_${arch}" ;;
  esac
}

get_download_url() {
  local version="$1"
  local target
  target="$(get_target)"

  echo "https://github.com/${REPO}/releases/download/${version}/ripgrep-${version}-${target}.tar.gz"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "ripgrep only supports version installs, not ref installs"
  fi

  local url target
  url="$(get_download_url "$version")"
  target="$(get_target)"

  mkdir -p "$download_path"
  download_file "$url" "$download_path/ripgrep.tar.gz"
  extract_tar_gz "$download_path/ripgrep.tar.gz" "$download_path"

  mkdir -p "$download_path/bin"
  mv "$download_path/ripgrep-${version}-${target}/rg" "$download_path/bin/"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  mkdir -p "$install_path/bin"
  install_binary "$download_path/bin/rg" "$install_path/bin/rg" "ripgrep"
}
