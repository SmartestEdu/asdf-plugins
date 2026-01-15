#!/usr/bin/env bash

# kubectl-slice - Split Kubernetes multi-YAML manifests into individual files
# Repository: https://github.com/patrickdappollonio/kubectl-slice

set -euo pipefail

readonly REPO="patrickdappollonio/kubectl-slice"

list_all_versions() {
  list_github_versions "$REPO" | sort_versions | tr '\n' ' '
}

get_download_url() {
  local version="$1"
  local os
  local arch

  os="$(get_os)"
  arch="$(get_arch)"

  # Map to kubectl-slice's naming conventions
  case "$os" in
    darwin) os="darwin" ;;
    linux) os="linux" ;;
  esac

  case "$arch" in
    amd64) arch="x86_64" ;;
    arm64) arch="arm64" ;;
    *) error_exit "kubectl-slice does not support architecture: $arch" ;;
  esac

  echo "https://github.com/${REPO}/releases/download/v${version}/kubectl-slice_${os}_${arch}.tar.gz"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "kubectl-slice only supports version installs, not ref installs"
  fi

  local url
  url="$(get_download_url "$version")"

  mkdir -p "$download_path/bin"
  download_file "$url" "$download_path/kubectl-slice.tar.gz"
  extract_tar_gz "$download_path/kubectl-slice.tar.gz" "$download_path/bin"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  mkdir -p "$install_path/bin"
  install_binary "$download_path/bin/kubectl-slice" "$install_path/bin/kubectl-slice" "kubectl-slice"
}
