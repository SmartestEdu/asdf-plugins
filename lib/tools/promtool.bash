#!/usr/bin/env bash

# promtool - Prometheus configuration checking tool
# Repository: https://github.com/prometheus/prometheus

set -euo pipefail

readonly REPO="prometheus/prometheus"

list_all_versions() {
  list_github_versions "$REPO" | sort_versions | tr '\n' ' '
}

get_download_url() {
  local version="$1"
  local os
  local arch

  os="$(get_os)"
  arch="$(get_arch)"

  # Map to prometheus naming conventions
  case "$arch" in
    amd64) arch="amd64" ;;
    arm64) arch="arm64" ;;
    386) arch="386" ;;
    *) error_exit "promtool does not support architecture: $arch" ;;
  esac

  echo "https://github.com/${REPO}/releases/download/v${version}/prometheus-${version}.${os}-${arch}.tar.gz"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "promtool only supports version installs, not ref installs"
  fi

  local url
  url="$(get_download_url "$version")"

  local os
  os="$(get_os)"

  local arch
  arch="$(get_arch)"
  case "$arch" in
    amd64) arch="amd64" ;;
    arm64) arch="arm64" ;;
    386) arch="386" ;;
  esac

  mkdir -p "$download_path/bin"
  download_file "$url" "$download_path/prometheus.tar.gz"
  extract_tar_gz "$download_path/prometheus.tar.gz" "$download_path"

  # Move promtool binary to bin directory
  mv "$download_path/prometheus-${version}.${os}-${arch}/promtool" "$download_path/bin/"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  mkdir -p "$install_path/bin"
  install_binary "$download_path/bin/promtool" "$install_path/bin/promtool" "promtool"
}
