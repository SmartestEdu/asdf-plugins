#!/usr/bin/env bash

# aws-vault - secure AWS credential storage; serves short-lived session credentials
# Repository: https://github.com/99designs/aws-vault

set -euo pipefail

readonly REPO="99designs/aws-vault"

list_all_versions() {
  list_github_versions "$REPO" | sort_versions | tr '\n' ' '
}

get_download_url() {
  local version="$1"
  local os
  local arch

  os="$(get_os)"
  arch="$(get_arch)"

  # Upstream darwin releases ship as .dmg only (no bare binary). Mac users
  # should install via `brew install aws-vault` until DMG handling is added.
  if [ "$os" != "linux" ]; then
    error_exit "aws-vault asdf plugin currently supports linux only; on macOS use 'brew install aws-vault'"
  fi

  case "$arch" in
    amd64|arm64|arm7|386) ;;
    *) error_exit "aws-vault does not support linux $arch" ;;
  esac

  echo "https://github.com/${REPO}/releases/download/v${version}/aws-vault-linux-${arch}"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "aws-vault only supports version installs, not ref installs"
  fi

  local url
  url="$(get_download_url "$version")"

  mkdir -p "$download_path/bin"
  download_file "$url" "$download_path/bin/aws-vault"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  mkdir -p "$install_path/bin"
  install_binary "$download_path/bin/aws-vault" "$install_path/bin/aws-vault" "aws-vault"
}
