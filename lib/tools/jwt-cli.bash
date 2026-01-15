#!/usr/bin/env bash

# jwt-cli - A command line tool to decode, encode and sign JWTs
# Repository: https://github.com/mike-engel/jwt-cli

set -euo pipefail

readonly REPO="mike-engel/jwt-cli"

list_all_versions() {
  list_github_versions "$REPO" | sort_versions | tr '\n' ' '
}

get_download_url() {
  local version="$1"
  local os

  os="$(get_os)"

  # jwt-cli uses simple naming: jwt-linux.tar.gz, jwt-macOS.tar.gz
  # Note: Using the musl variant for Linux for better compatibility
  case "$os" in
    darwin)
      os="macOS"
      ;;
    linux)
      os="linux-musl"
      ;;
  esac

  echo "https://github.com/${REPO}/releases/download/${version}/jwt-${os}.tar.gz"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "jwt-cli only supports version installs, not ref installs"
  fi

  local url
  url="$(get_download_url "$version")"

  mkdir -p "$download_path/bin"
  download_file "$url" "$download_path/jwt.tar.gz"
  extract_tar_gz "$download_path/jwt.tar.gz" "$download_path"
  mv "$download_path/jwt" "$download_path/bin/"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  mkdir -p "$install_path/bin"
  install_binary "$download_path/bin/jwt" "$install_path/bin/jwt" "jwt-cli"
}
