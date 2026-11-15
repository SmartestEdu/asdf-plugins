#!/usr/bin/env bash

# fallow - Codebase intelligence for TypeScript and JavaScript
# Repository: https://github.com/fallow-rs/fallow
#
# Release tags are formatted "v<version>"; assets are
# "fallow-<rust-target>.tar.gz". The archive holds the fallow CLI plus
# companion binaries (fallow-lsp, and in newer releases fallow-mcp and
# fallow-similar-code). The published SHA256SUMS file doesn't list the
# tarballs, so there's nothing to verify them against.

set -euo pipefail

readonly REPO="fallow-rs/fallow"

list_all_versions() {
  list_github_versions "$REPO" |
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' |
    sort_versions |
    tr '\n' ' '
}

get_target() {
  local os arch
  os="$(get_os)"
  arch="$(get_arch)"

  case "${os}_${arch}" in
    linux_amd64) echo "x86_64-unknown-linux-gnu" ;;
    linux_arm64) echo "aarch64-unknown-linux-gnu" ;;
    darwin_amd64) echo "x86_64-apple-darwin" ;;
    darwin_arm64) echo "aarch64-apple-darwin" ;;
    *) error_exit "fallow does not support platform: ${os}_${arch}" ;;
  esac
}

get_download_url() {
  local version="$1"
  local target
  target="$(get_target)"

  echo "https://github.com/${REPO}/releases/download/v${version}/fallow-${target}.tar.gz"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "fallow only supports version installs, not ref installs"
  fi

  local url archive
  url="$(get_download_url "$version")"
  archive="${download_path}/fallow.tar.gz"

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

  [ -f "${download_path}/fallow" ] || error_exit "Could not find 'fallow' binary in extracted archive"

  mkdir -p "$install_path/bin"
  local bin name
  for bin in "${download_path}"/fallow*; do
    # Skip anything that isn't an executable file (e.g. docs or completions)
    if [ ! -f "$bin" ] || [ ! -x "$bin" ]; then
      continue
    fi
    name="$(basename "$bin")"
    install_binary "$bin" "${install_path}/bin/${name}" "$name"
  done
}
