#!/usr/bin/env bash

# github-cli (gh) - GitHub's official command line tool
# Repository: https://github.com/cli/cli

set -euo pipefail

readonly REPO="cli/cli"

list_all_versions() {
  list_github_versions "$REPO" | sort_versions | tr '\n' ' '
}

get_download_url() {
  local version="$1"
  local os
  local arch

  os="$(get_os)"
  arch="$(get_arch)"

  # Map to gh's naming conventions
  case "$os" in
    darwin) os="macOS" ;;
    linux) os="linux" ;;
  esac

  case "$arch" in
    amd64) arch="amd64" ;;
    arm64) arch="arm64" ;;
    386) arch="386" ;;
    *) error_exit "github-cli does not support architecture: $arch" ;;
  esac

  echo "https://github.com/${REPO}/releases/download/v${version}/gh_${version}_${os}_${arch}.tar.gz"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "github-cli only supports version installs, not ref installs"
  fi

  local url
  url="$(get_download_url "$version")"

  local os
  os="$(get_os)"
  case "$os" in
    darwin) os="macOS" ;;
    linux) os="linux" ;;
  esac

  local arch
  arch="$(get_arch)"

  mkdir -p "$download_path"
  download_file "$url" "$download_path/gh.tar.gz"
  extract_tar_gz "$download_path/gh.tar.gz" "$download_path"

  # Move binary to expected location
  mkdir -p "$download_path/bin"
  mv "$download_path/gh_${version}_${os}_${arch}/bin/gh" "$download_path/bin/"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  mkdir -p "$install_path/bin"
  install_binary "$download_path/bin/gh" "$install_path/bin/gh" "github-cli"
}
