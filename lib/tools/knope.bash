#!/usr/bin/env bash

# knope - A command line tool for automating common development tasks
# Repository: https://github.com/knope-dev/knope

set -euo pipefail

readonly REPO="knope-dev/knope"

list_all_versions() {
  local versions
  versions="$(github_releases "$REPO" | grep -oE '"tag_name": *"[^"]+"' | sed 's/"tag_name": *"//;s/"//' | grep '^knope/v' | sed 's|^knope/v||')"

  echo "$versions" | sort_versions | tr '\n' ' '
}

get_target() {
  local os arch

  os="$(get_os)"
  arch="$(get_arch)"

  case "${os}_${arch}" in
    linux_amd64)  echo "x86_64-unknown-linux-musl" ;;
    linux_arm64)  echo "aarch64-unknown-linux-musl" ;;
    darwin_amd64) echo "x86_64-apple-darwin" ;;
    darwin_arm64) echo "aarch64-apple-darwin" ;;
    *) error_exit "knope does not support platform: ${os}_${arch}" ;;
  esac
}

get_download_url() {
  local version="$1"
  local target
  target="$(get_target)"

  echo "https://github.com/${REPO}/releases/download/knope/v${version}/knope-${target}.tgz"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "knope only supports version installs, not ref installs"
  fi

  local url
  url="$(get_download_url "$version")"

  mkdir -p "$download_path"
  download_file "$url" "$download_path/knope.tgz"
  extract_tar_gz "$download_path/knope.tgz" "$download_path"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  mkdir -p "$install_path/bin"
  install_binary "$download_path/knope" "$install_path/bin/knope" "knope"
}
