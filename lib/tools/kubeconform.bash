#!/usr/bin/env bash

# kubeconform - Kubernetes manifest validation
# Repository: https://github.com/yannh/kubeconform

set -euo pipefail

readonly REPO="yannh/kubeconform"

list_all_versions() {
  list_github_versions "$REPO" | sort_versions | tr '\n' ' '
}

get_download_url() {
  local version="$1"
  local os
  local arch

  os="$(get_os)"
  arch="$(get_arch)"

  # Map to kubeconform's naming conventions
  case "$arch" in
    amd64) arch="amd64" ;;
    arm64) arch="arm64" ;;
    *) error_exit "kubeconform does not support architecture: $arch" ;;
  esac

  echo "https://github.com/${REPO}/releases/download/v${version}/kubeconform-${os}-${arch}.tar.gz"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "kubeconform only supports version installs, not ref installs"
  fi

  local url
  url="$(get_download_url "$version")"

  mkdir -p "$download_path/bin"
  download_file "$url" "$download_path/kubeconform.tar.gz"
  extract_tar_gz "$download_path/kubeconform.tar.gz" "$download_path/bin"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  mkdir -p "$install_path/bin"
  install_binary "$download_path/bin/kubeconform" "$install_path/bin/kubeconform" "kubeconform"
}
