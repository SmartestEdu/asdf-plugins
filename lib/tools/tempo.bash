#!/usr/bin/env bash

# tempo - Grafana Tempo and its command-line tools
# Repository: https://github.com/grafana/tempo

set -euo pipefail

readonly REPO="grafana/tempo"

list_all_versions() {
  list_github_versions "$REPO" |
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' |
    sort_versions |
    tr '\n' ' '
}

get_download_url() {
  local version="$1"
  local os arch
  os="$(get_os)"
  arch="$(get_arch)"

  # Current upstream releases do not publish macOS binaries.
  case "$os" in
    linux) ;;
    *) error_exit "tempo only supports Linux release binaries; use Docker for config validation on $os" ;;
  esac
  case "$arch" in
    amd64 | arm64) ;;
    *) error_exit "tempo does not support architecture: $arch" ;;
  esac

  echo "https://github.com/${REPO}/releases/download/v${version}/tempo_${version}_${os}_${arch}.tar.gz"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "tempo only supports version installs, not ref installs"
  fi

  local url archive
  url="$(get_download_url "$version")"
  archive="${download_path}/tempo.tar.gz"

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

  # Config verification uses tempo; tempo-cli provides query/debug commands.
  local binary
  for binary in tempo tempo-cli; do
    install_binary "$download_path/$binary" "$install_path/bin/$binary" "$binary"
  done
}
