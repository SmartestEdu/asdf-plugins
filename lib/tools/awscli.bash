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

  case "$os" in
    darwin)
      # macOS uses a universal .pkg installer
      echo "https://awscli.amazonaws.com/AWSCLIV2-${version}.pkg"
      ;;
    linux)
      case "$arch" in
        amd64) arch="x86_64" ;;
        arm64) arch="aarch64" ;;
        *) error_exit "awscli does not support architecture: $arch on Linux" ;;
      esac
      echo "https://awscli.amazonaws.com/awscli-exe-${os}-${arch}-${version}.zip"
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

  local os
  os="$(get_os)"

  case "$os" in
    darwin)
      download_file "$url" "$download_path/awscli.pkg"
      pkgutil --expand-full "$download_path/awscli.pkg" "$download_path/expanded"
      ;;
    linux)
      download_file "$url" "$download_path/awscli.zip"
      extract_zip "$download_path/awscli.zip" "$download_path"
      ;;
  esac
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  local os
  os="$(get_os)"

  case "$os" in
    darwin)
      local payload_dir="$download_path/expanded/aws-cli.pkg/Payload/aws-cli"
      if [ ! -d "$payload_dir" ]; then
        payload_dir="$(find "$download_path/expanded" -type d -name "aws-cli" -path "*/Payload/*" | head -1)"
      fi
      if [ ! -d "$payload_dir" ]; then
        error_exit "Could not find aws-cli in expanded pkg"
      fi

      mkdir -p "$install_path"
      cp -R "$payload_dir" "$install_path/aws-cli"

      mkdir -p "$install_path/bin"
      ln -sf "$install_path/aws-cli/v2/current/bin/aws" "$install_path/bin/aws"
      ln -sf "$install_path/aws-cli/v2/current/bin/aws_completer" "$install_path/bin/aws_completer"
      ;;
    linux)
      "$download_path/aws/install" --install-dir "$install_path" --bin-dir "$install_path/bin" || error_exit "Failed to install awscli"
      ;;
  esac

  echo "Installed awscli to $install_path/bin/aws"
}
