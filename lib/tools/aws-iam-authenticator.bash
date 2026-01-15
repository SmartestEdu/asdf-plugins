#!/usr/bin/env bash

# aws-iam-authenticator - AWS IAM Authenticator for Kubernetes
# Repository: https://github.com/kubernetes-sigs/aws-iam-authenticator

set -euo pipefail

readonly REPO="kubernetes-sigs/aws-iam-authenticator"

list_all_versions() {
  list_github_versions "$REPO" | sort_versions | tr '\n' ' '
}

get_download_url() {
  local version="$1"
  local os
  local arch

  os="$(get_os)"
  arch="$(get_arch)"

  # Map to aws-iam-authenticator's naming conventions
  case "$arch" in
    amd64) arch="amd64" ;;
    arm64) arch="arm64" ;;
    *) error_exit "aws-iam-authenticator does not support architecture: $arch" ;;
  esac

  echo "https://github.com/${REPO}/releases/download/v${version}/aws-iam-authenticator_${version}_${os}_${arch}"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "aws-iam-authenticator only supports version installs, not ref installs"
  fi

  local url
  url="$(get_download_url "$version")"

  mkdir -p "$download_path/bin"
  download_file "$url" "$download_path/bin/aws-iam-authenticator"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  mkdir -p "$install_path/bin"
  install_binary "$download_path/bin/aws-iam-authenticator" "$install_path/bin/aws-iam-authenticator" "aws-iam-authenticator"
}
