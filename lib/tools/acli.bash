#!/usr/bin/env bash

# acli - Atlassian CLI
# Documentation: https://developer.atlassian.com/cloud/acli/

set -euo pipefail

list_all_versions() {
  # Atlassian only provides "latest" downloads without versioned archives.
  # We fetch the current version from the APT repository metadata.
  # The version format in APT is "1.3.11~stable", we convert to "1.3.11-stable"
  local version
  version=$(curl_wrapper -fsSL "https://acli.atlassian.com/linux/deb/dists/stable/main/binary-amd64/Packages" 2>/dev/null \
    | grep -E "^Version:" \
    | head -n1 \
    | sed 's/^Version: //' \
    | tr '~' '-')

  if [ -n "$version" ]; then
    echo "$version"
  else
    # Fallback if APT metadata fetch fails
    echo "latest"
  fi
}

get_download_url() {
  local version="$1"
  local os
  local arch

  os="$(get_os)"
  arch="$(get_arch)"

  # Only amd64 and arm64 are supported
  case "$arch" in
    amd64 | arm64) ;;
    *) error_exit "acli does not support architecture: $arch" ;;
  esac

  # URL pattern: https://acli.atlassian.com/{os}/latest/acli_{os}_{arch}/acli
  echo "https://acli.atlassian.com/${os}/latest/acli_${os}_${arch}/acli"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "acli only supports version installs, not ref installs"
  fi

  local url
  url="$(get_download_url "$version")"

  mkdir -p "$download_path/bin"
  download_file "$url" "$download_path/bin/acli"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  # Verify the downloaded binary matches the requested version
  # Atlassian only provides "latest" downloads, so we need to check
  chmod +x "$download_path/bin/acli"
  local actual_version
  actual_version=$("$download_path/bin/acli" --version 2>/dev/null | sed 's/^acli version //')

  if [ "$version" != "latest" ] && [ -n "$actual_version" ] && [ "$actual_version" != "$version" ]; then
    error_exit "Version mismatch: requested $version but Atlassian is serving $actual_version. Only the latest version is available for download."
  fi

  mkdir -p "$install_path/bin"
  install_binary "$download_path/bin/acli" "$install_path/bin/acli" "acli"
}
