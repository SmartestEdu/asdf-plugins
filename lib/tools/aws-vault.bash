#!/usr/bin/env bash

# aws-vault - secure AWS credential storage; serves short-lived session credentials
# Repository: https://github.com/ByteNess/aws-vault
#
# Tracking the ByteNess fork rather than the original 99designs/aws-vault: the
# upstream's release cadence has slowed significantly while ByteNess is actively
# cutting releases, and ByteNess ships bare darwin binaries (the upstream ships
# .dmg only on macOS, which would require hdiutil mounting).

set -euo pipefail

readonly REPO="ByteNess/aws-vault"

list_all_versions() {
  list_github_versions "$REPO" | sort_versions | tr '\n' ' '
}

get_download_url() {
  local version="$1"
  local os
  local arch

  os="$(get_os)"
  arch="$(get_arch)"

  case "$os" in
    linux)
      case "$arch" in
        amd64|arm64|ppc64le) ;;
        *) error_exit "aws-vault does not support linux $arch" ;;
      esac
      ;;
    darwin)
      case "$arch" in
        amd64|arm64) ;;
        *) error_exit "aws-vault does not support darwin $arch" ;;
      esac
      ;;
    *)
      error_exit "aws-vault does not support OS: $os"
      ;;
  esac

  echo "https://github.com/${REPO}/releases/download/v${version}/aws-vault-${os}-${arch}"
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
