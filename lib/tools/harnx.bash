#!/usr/bin/env bash

# harnx - https://github.com/dobesv/harnx
# Release tags are formatted "harnx/v<version>"; assets are
# "harnx-v<version>-<rust-target>.tar.gz" containing a single `harnx` binary.

set -euo pipefail

readonly REPO="dobesv/harnx"

list_all_versions() {
  # Tags look like "harnx/v0.32.4" -> strip "harnx/v", keep x.y.z, sort.
  list_github_versions "$REPO" |
    sed -n 's#^harnx/v##p' |
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' |
    sort_versions |
    tr '\n' ' '
}

# Map the current platform to harnx's Rust target triple.
get_target() {
  local os arch
  os="$(get_os)"
  arch="$(get_arch)"
  case "${os}_${arch}" in
    linux_amd64)  echo "x86_64-unknown-linux-musl" ;;
    linux_arm64)  echo "aarch64-unknown-linux-musl" ;;
    darwin_amd64) echo "x86_64-apple-darwin" ;;
    darwin_arm64) echo "aarch64-apple-darwin" ;;
    *) error_exit "harnx does not support platform: ${os}_${arch}" ;;
  esac
}

get_download_url() {
  local version="$1"
  local target
  target="$(get_target)"

  echo "https://github.com/${REPO}/releases/download/harnx/v${version}/harnx-v${version}-${target}.tar.gz"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "harnx only supports version installs, not ref installs"
  fi

  local url archive
  url="$(get_download_url "$version")"
  archive="${download_path}/harnx.tar.gz"

  mkdir -p "$download_path"
  download_file "$url" "$archive"
  extract_tar_gz "$archive" "$download_path"
  rm -f "$archive"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  mkdir -p "$install_path/bin"
  install_binary "${download_path}/harnx" "${install_path}/bin/harnx" "harnx"
}
