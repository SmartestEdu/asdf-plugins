#!/usr/bin/env bash

# kubectl - Kubernetes command-line tool
# Repository: https://github.com/kubernetes/kubernetes

set -euo pipefail

readonly REPO="https://github.com/kubernetes/kubernetes.git"

list_all_versions() {
  list_git_versions "$REPO" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort_versions | tr '\n' ' '
}

get_download_url() {
  local version="$1"
  local os
  local arch

  os="$(get_os)"
  arch="$(get_arch)"

  # Map to kubectl's naming conventions
  case "$arch" in
    amd64) arch="amd64" ;;
    arm64) arch="arm64" ;;
    386) arch="386" ;;
    *) error_exit "kubectl does not support architecture: $arch" ;;
  esac

  echo "https://dl.k8s.io/release/v${version}/bin/${os}/${arch}/kubectl"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "kubectl only supports version installs, not ref installs"
  fi

  local url
  url="$(get_download_url "$version")"

  mkdir -p "$download_path/bin"
  download_file "$url" "$download_path/bin/kubectl"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  mkdir -p "$install_path/bin"
  install_binary "$download_path/bin/kubectl" "$install_path/bin/kubectl" "kubectl"
}
