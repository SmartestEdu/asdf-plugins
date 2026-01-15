#!/usr/bin/env bash

# kustomize - Kubernetes native configuration management
# Repository: https://github.com/kubernetes-sigs/kustomize

set -euo pipefail

readonly REPO="kubernetes-sigs/kustomize"

list_all_versions() {
  list_github_versions "$REPO" "kustomize/v" | sed 's|kustomize/v||' | sort_versions | tr '\n' ' '
}

get_download_url() {
  local version="$1"
  local os
  local arch

  os="$(get_os)"
  arch="$(get_arch)"

  # Map to kustomize's naming conventions
  case "$arch" in
    amd64) arch="amd64" ;;
    arm64) arch="arm64" ;;
    *) error_exit "kustomize does not support architecture: $arch" ;;
  esac

  echo "https://github.com/${REPO}/releases/download/kustomize%2Fv${version}/kustomize_v${version}_${os}_${arch}.tar.gz"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "kustomize only supports version installs, not ref installs"
  fi

  local url
  url="$(get_download_url "$version")"

  mkdir -p "$download_path/bin"
  download_file "$url" "$download_path/kustomize.tar.gz"
  extract_tar_gz "$download_path/kustomize.tar.gz" "$download_path/bin"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  mkdir -p "$install_path/bin"
  install_binary "$download_path/bin/kustomize" "$install_path/bin/kustomize" "kustomize"
}
