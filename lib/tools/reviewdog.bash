#!/usr/bin/env bash

# reviewdog - Automated code review tool integrated with any code analysis tools
# Repository: https://github.com/reviewdog/reviewdog
#
# Release tags are formatted "v<version>"; assets are
# "reviewdog_<version>_<OS>_<arch>.tar.gz" containing a single "reviewdog"
# binary at the archive root alongside LICENSE and README.md.

set -euo pipefail

readonly REPO="reviewdog/reviewdog"

list_all_versions() {
  # Tags look like "v0.21.0"; list_github_versions already strips the leading
  # "v", so we keep x.y.z entries and sort.
  list_github_versions "$REPO" |
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' |
    sort_versions |
    tr '\n' ' '
}

# Map the current platform to reviewdog's <OS>_<arch> asset naming.
# reviewdog capitalizes the OS (Darwin/Linux) and uses x86_64 for amd64.
get_target() {
  local os arch
  os="$(get_os)"
  arch="$(get_arch)"
  case "$os" in
    darwin) os="Darwin" ;;
    linux) os="Linux" ;;
  esac
  case "$arch" in
    amd64) arch="x86_64" ;;
    arm64) arch="arm64" ;;
    386) arch="i386" ;;
    arm) arch="armv6" ;;
    *) error_exit "reviewdog does not support architecture: $arch" ;;
  esac
  echo "${os}_${arch}"
}

get_download_url() {
  local version="$1"
  local target
  target="$(get_target)"

  echo "https://github.com/${REPO}/releases/download/v${version}/reviewdog_${version}_${target}.tar.gz"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "reviewdog only supports version installs, not ref installs"
  fi

  local url archive
  url="$(get_download_url "$version")"
  archive="${download_path}/reviewdog.tar.gz"

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

  # The tarball extracts a single "reviewdog" binary at the archive root.
  mkdir -p "$install_path/bin"
  install_binary \
    "${download_path}/reviewdog" \
    "${install_path}/bin/reviewdog" "reviewdog"
}
