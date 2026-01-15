#!/usr/bin/env bash

# caddy - Fast web server with automatic HTTPS
# Repository: https://github.com/caddyserver/caddy

set -euo pipefail

readonly REPO="caddyserver/caddy"

list_all_versions() {
  list_github_versions "$REPO" | sort_versions | tr '\n' ' '
}

get_download_url() {
  local version="$1"
  local os
  local arch

  os="$(get_os)"
  arch="$(get_arch)"

  # Map to caddy's naming conventions
  case "$arch" in
    amd64) arch="amd64" ;;
    arm64) arch="arm64" ;;
    *) error_exit "caddy does not support architecture: $arch" ;;
  esac

  echo "https://github.com/${REPO}/releases/download/v${version}/caddy_${version}_${os}_${arch}.tar.gz"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "caddy only supports version installs, not ref installs"
  fi

  local url
  url="$(get_download_url "$version")"

  mkdir -p "$download_path/bin"
  download_file "$url" "$download_path/caddy.tar.gz"
  extract_tar_gz "$download_path/caddy.tar.gz" "$download_path/bin"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  mkdir -p "$install_path/bin"
  install_binary "$download_path/bin/caddy" "$install_path/bin/caddy" "caddy"
}
