#!/usr/bin/env bash

# awscli - AWS Command Line Interface
# Repository: https://github.com/aws/aws-cli

set -euo pipefail

readonly REPO="aws/aws-cli"

list_all_versions() {
  list_github_versions "$REPO" | sort_versions | tr '\n' ' '
}

get_download_url() {
  local version="$1"
  local os
  local arch

  os="$(get_os)"
  arch="$(get_arch)"

  # AWS CLI uses different URLs for different platforms
  case "$os" in
    darwin)
      # macOS uses pkg installer, but we can use the bundled installer
      echo "https://awscli.amazonaws.com/awscli-exe-${os}-${arch}.zip"
      ;;
    linux)
      case "$arch" in
        amd64) arch="x86_64" ;;
        arm64) arch="aarch64" ;;
        *) error_exit "awscli does not support architecture: $arch on Linux" ;;
      esac
      echo "https://awscli.amazonaws.com/awscli-exe-${os}-${arch}.zip"
      ;;
    *)
      error_exit "awscli does not support OS: $os"
      ;;
  esac
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "awscli only supports version installs, not ref installs"
  fi

  local url
  url="$(get_download_url "$version")"

  mkdir -p "$download_path"
  download_file "$url" "$download_path/awscli.zip"
  extract_zip "$download_path/awscli.zip" "$download_path"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  # Run the AWS CLI installer
  "$download_path/aws/install" --install-dir "$install_path" --bin-dir "$install_path/bin" || error_exit "Failed to install awscli"

  echo "Installed awscli to $install_path/bin/aws"
}
