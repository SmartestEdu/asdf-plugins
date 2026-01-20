#!/usr/bin/env bash

# acli - Atlassian CLI
# Documentation: https://developer.atlassian.com/cloud/acli/

set -euo pipefail

list_all_versions() {
  # Get latest version from APT metadata to determine the upper bound
  local latest
  latest=$(curl_wrapper -fsSL "https://acli.atlassian.com/linux/deb/dists/stable/main/binary-amd64/Packages" 2>/dev/null \
    | grep -E "^Version:" \
    | head -n1 \
    | sed 's/^Version: //' \
    | tr '~' '-')

  if [ -z "$latest" ]; then
    echo "latest"
    return
  fi

  # Parse version components (e.g., "1.3.11-stable" -> major=1, minor=3, patch=11)
  local latest_minor latest_patch
  latest_minor=$(echo "$latest" | cut -d. -f2)
  latest_patch=$(echo "$latest" | cut -d. -f3 | cut -d- -f1)

  # Generate candidate versions and check which exist (last ~10 versions for speed)
  # URL pattern: https://acli.atlassian.com/linux/{version}/acli_{version}_linux_amd64.tar.gz
  local versions=()
  local count=0
  local max_versions=10

  # Check recent stable versions, working backwards from latest
  for patch in $(seq "$latest_patch" -1 0); do
    local v="1.${latest_minor}.${patch}-stable"
    if curl_wrapper -sfI "https://acli.atlassian.com/linux/${v}/acli_${v}_linux_amd64.tar.gz" >/dev/null 2>&1; then
      versions+=("$v")
      count=$((count + 1))
      [ "$count" -ge "$max_versions" ] && break
    fi
  done

  # If we need more versions, check previous minor version
  if [ "$count" -lt "$max_versions" ] && [ "$latest_minor" -gt 1 ]; then
    local prev_minor=$((latest_minor - 1))
    for patch in $(seq 20 -1 0); do
      local v="1.${prev_minor}.${patch}-stable"
      if curl_wrapper -sfI "https://acli.atlassian.com/linux/${v}/acli_${v}_linux_amd64.tar.gz" >/dev/null 2>&1; then
        versions+=("$v")
        count=$((count + 1))
        [ "$count" -ge "$max_versions" ] && break
      fi
    done
  fi

  # Sort and output versions
  printf '%s\n' "${versions[@]}" | sort_versions | tr '\n' ' '
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

  if [ "$version" = "latest" ]; then
    # Use the latest binary URL
    echo "https://acli.atlassian.com/${os}/latest/acli_${os}_${arch}/acli"
  else
    # Use versioned tarball URL
    echo "https://acli.atlassian.com/${os}/${version}/acli_${version}_${os}_${arch}.tar.gz"
  fi
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

  mkdir -p "$download_path"

  if [ "$version" = "latest" ]; then
    # Download binary directly
    mkdir -p "$download_path/bin"
    download_file "$url" "$download_path/bin/acli"
  else
    # Download and extract tarball
    download_file "$url" "$download_path/acli.tar.gz"
    extract_tar_gz "$download_path/acli.tar.gz" "$download_path"
  fi
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  local binary
  if [ "$version" = "latest" ]; then
    binary="$download_path/bin/acli"
  else
    # Find the acli binary in extracted tarball directory
    binary=$(find "$download_path" -name "acli" -type f 2>/dev/null | head -n1)
  fi

  if [ -z "$binary" ] || [ ! -f "$binary" ]; then
    error_exit "Could not find acli binary in download"
  fi

  mkdir -p "$install_path/bin"
  install_binary "$binary" "$install_path/bin/acli" "acli"
}
