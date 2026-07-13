#!/usr/bin/env bash

# luchta - https://github.com/dobesv/luchta
# Release tags are formatted "luchta/v<version>"; assets are
# "luchta-v<version>-<rust-target>.tar.gz" containing the `luchta` binary plus
# its worker binaries (e.g. luchta-bash-worker, luchta-yarn-worker).

set -euo pipefail

readonly REPO="dobesv/luchta"

list_all_versions() {
  # Tags look like "luchta/v0.1.1" -> strip "luchta/v", keep x.y.z, sort.
  list_github_versions "$REPO" |
    sed -n 's#^luchta/v##p' |
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' |
    sort_versions |
    tr '\n' ' '
}

# Map the current platform to luchta's Rust target triple.
get_target() {
  local os arch
  os="$(get_os)"
  arch="$(get_arch)"
  case "${os}_${arch}" in
    linux_amd64)  echo "x86_64-unknown-linux-musl" ;;
    linux_arm64)  echo "aarch64-unknown-linux-musl" ;;
    darwin_amd64) echo "x86_64-apple-darwin" ;;
    darwin_arm64) echo "aarch64-apple-darwin" ;;
    *) error_exit "luchta does not support platform: ${os}_${arch}" ;;
  esac
}

get_download_url() {
  local version="$1"
  local target
  target="$(get_target)"

  echo "https://github.com/${REPO}/releases/download/luchta/v${version}/luchta-v${version}-${target}.tar.gz"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "luchta only supports version installs, not ref installs"
  fi

  local url archive
  url="$(get_download_url "$version")"
  archive="${download_path}/luchta.tar.gz"

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

  # The tarball bundles `luchta` alongside its worker binaries
  # (luchta-bash-worker, luchta-yarn-worker, ...). Install every executable that
  # was extracted so new workers are picked up automatically. Skip any
  # non-executable files (e.g. LICENSE/README) so they don't pollute bin/.
  mkdir -p "$install_path/bin"
  local src name found=0
  for src in "${download_path}"/*; do
    if [ ! -f "$src" ] || [ ! -x "$src" ]; then
      continue
    fi
    name="$(basename "$src")"
    install_binary "$src" "${install_path}/bin/${name}" "$name"
    found=1
  done
  [ "$found" -eq 1 ] || error_exit "luchta: no binaries found in ${download_path}"
}
