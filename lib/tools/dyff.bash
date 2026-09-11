#!/usr/bin/env bash

# dyff - YAML and Kubernetes manifest comparison tool
# Repository: https://github.com/homeport/dyff
#
# Release tags are formatted "v<version>"; assets are
# "dyff_<version>_<os>_<arch>.tar.gz" containing the dyff binary.

set -euo pipefail

readonly REPO="homeport/dyff"

list_all_versions() {
  list_github_versions "$REPO" |
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' |
    sort_versions |
    tr '\n' ' '
}

get_target() {
  local os arch
  os="$(get_os)"
  arch="$(get_arch)"

  case "${os}_${arch}" in
    darwin_amd64 | darwin_arm64 | linux_amd64 | linux_arm64)
      echo "${os}_${arch}"
      ;;
    *)
      error_exit "dyff does not support platform: ${os}_${arch}"
      ;;
  esac
}

get_download_url() {
  local version="$1"
  local target
  target="$(get_target)"

  echo "https://github.com/${REPO}/releases/download/v${version}/dyff_${version}_${target}.tar.gz"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "dyff only supports version installs, not ref installs"
  fi

  local url archive
  url="$(get_download_url "$version")"
  archive="${download_path}/dyff.tar.gz"

  mkdir -p "$download_path"
  download_file "$url" "$archive"
  extract_tar_gz "$archive" "$download_path"
  rm -f "$archive"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  mkdir -p "$install_path/bin"
  install_binary "${download_path}/dyff" "${install_path}/bin/dyff" "dyff"
}
