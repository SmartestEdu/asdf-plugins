#!/usr/bin/env bash

set -euo pipefail

# Wrap curl to ensure User-Agent header is set
curl_wrapper() {
  curl -A "asdf (https://github.com/asdf-vm/asdf)" "$@"
}

# Sort versions semantically
# Adapted from https://github.com/rbenv/ruby-build
sort_versions() {
  sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z.\1/; s/$/.z/; G; s/\n/ /' |
    LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

# Error handling
error_exit() {
  echo "$1" >&2
  exit "${2:-1}"
}

# Get the tool name from the plugin directory
get_tool_name() {
  local script_dir
  script_dir="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  basename "$(dirname "${script_dir}")"
}

# Get OS type
get_os() {
  local os
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  case "$os" in
    darwin) echo "darwin" ;;
    linux) echo "linux" ;;
    *) error_exit "Unsupported operating system: $os" ;;
  esac
}

# Get architecture
get_arch() {
  local arch
  arch="$(uname -m)"
  case "$arch" in
    x86_64 | amd64) echo "amd64" ;;
    aarch64 | arm64) echo "arm64" ;;
    i686 | i386) echo "386" ;;
    armv7l | armv6l) echo "arm" ;;
    *) error_exit "Unsupported architecture: $arch" ;;
  esac
}

# Get OS and arch in format commonly used by Go binaries
get_platform() {
  echo "$(get_os)_$(get_arch)"
}

# Download file with progress
download_file() {
  local url="$1"
  local dest="$2"

  echo "Downloading from $url"
  curl_wrapper -fsSL -o "$dest" "$url" || error_exit "Failed to download from $url"
}

# Extract tar.gz
extract_tar_gz() {
  local archive="$1"
  local dest="${2:-.}"

  echo "Extracting $archive"
  tar -xzf "$archive" -C "$dest" || error_exit "Failed to extract $archive"
}

# Extract zip
extract_zip() {
  local archive="$1"
  local dest="${2:-.}"

  echo "Extracting $archive"
  unzip -q "$archive" -d "$dest" || error_exit "Failed to extract $archive"
}

# Check if command exists
command_exists() {
  command -v "$1" &>/dev/null
}

# Install a single binary
install_binary() {
  local src="$1"
  local dest="$2"
  local name="$3"

  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest" || error_exit "Failed to copy binary"
  chmod +x "$dest" || error_exit "Failed to make binary executable"
  echo "Installed $name to $dest"
}

# Query GitHub releases API
github_releases() {
  local repo="$1"
  local url="https://api.github.com/repos/${repo}/releases"

  if [ -n "${GITHUB_API_TOKEN:-}" ]; then
    curl_wrapper -fsSL "$url" -H "Authorization: token $GITHUB_API_TOKEN"
  else
    curl_wrapper -fsSL "$url"
  fi
}

# Get latest version from GitHub releases
get_latest_version() {
  local repo="$1"
  github_releases "$repo" | grep -oE '"tag_name": *"[^"]+"' | head -n1 | sed 's/"tag_name": *"//;s/"//' | sed 's/^v//'
}

# List all versions from GitHub releases
list_github_versions() {
  local repo="$1"
  local filter="${2:-}"

  local versions
  versions="$(github_releases "$repo" | grep -oE '"tag_name": *"[^"]+"' | sed 's/"tag_name": *"//;s/"//')"

  if [ -n "$filter" ]; then
    versions="$(echo "$versions" | grep -E "$filter")"
  fi

  # Remove 'v' prefix if present
  echo "$versions" | sed 's/^v//'
}

# List all versions from git tags
list_git_versions() {
  local repo="$1"
  local filter="${2:-}"

  local versions
  versions="$(git ls-remote --tags --refs "$repo" | grep -oE 'refs/tags/.*' | sed 's|refs/tags/||')"

  if [ -n "$filter" ]; then
    versions="$(echo "$versions" | grep -E "$filter")"
  fi

  # Remove 'v' prefix if present
  echo "$versions" | sed 's/^v//'
}
