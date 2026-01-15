#!/usr/bin/env bash

# amazon-ecr-credential-helper - Amazon ECR Docker Credential Helper
# Repository: https://github.com/awslabs/amazon-ecr-credential-helper

set -euo pipefail

readonly REPO="awslabs/amazon-ecr-credential-helper"

list_all_versions() {
  list_github_versions "$REPO" | sort_versions | tr '\n' ' '
}

get_download_url() {
  local version="$1"
  local os
  local arch

  os="$(get_os)"
  arch="$(get_arch)"

  # Map to credential helper's naming conventions
  case "$arch" in
    amd64) arch="amd64" ;;
    arm64) arch="arm64" ;;
    *) error_exit "amazon-ecr-credential-helper does not support architecture: $arch" ;;
  esac

  echo "https://amazon-ecr-credential-helper-releases.s3.us-east-2.amazonaws.com/${version}/${os}-${arch}/docker-credential-ecr-login"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "amazon-ecr-credential-helper only supports version installs, not ref installs"
  fi

  local url
  url="$(get_download_url "$version")"

  mkdir -p "$download_path/bin"
  download_file "$url" "$download_path/bin/docker-credential-ecr-login"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  mkdir -p "$install_path/bin"
  install_binary "$download_path/bin/docker-credential-ecr-login" "$install_path/bin/docker-credential-ecr-login" "amazon-ecr-credential-helper"
}
