#!/usr/bin/env bash

# tmux - Terminal multiplexer
# Repository: https://github.com/tmux/tmux

set -euo pipefail

readonly REPO="tmux/tmux"
readonly LIBEVENT_VERSION="2.1.12"

list_all_versions() {
  list_github_versions "$REPO" | sort_versions | tr '\n' ' '
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "tmux only supports version installs, not ref installs"
  fi

  # Download tmux source from GitHub archive (works better with autogen.sh)
  local url="https://github.com/${REPO}/archive/${version}.zip"

  mkdir -p "$download_path"

  if ! command_exists unzip; then
    error_exit "unzip is required to install tmux. Please install unzip first."
  fi

  echo "Downloading tmux ${version}..."
  download_file "$url" "$download_path/tmux.zip"

  echo "Extracting tmux..."
  unzip -q "$download_path/tmux.zip" -d "$download_path" || error_exit "Failed to extract tmux"
}

install_libevent() {
  local install_path="$1"
  local tmp_dir="$2"

  echo "Building libevent ${LIBEVENT_VERSION}..."

  cd "$tmp_dir"

  local libevent_url="https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VERSION}-stable/libevent-${LIBEVENT_VERSION}-stable.tar.gz"

  curl_wrapper -fsSL -o libevent.tar.gz "$libevent_url" || error_exit "Failed to download libevent"
  tar -zxf libevent.tar.gz || error_exit "Failed to extract libevent"

  cd "libevent-${LIBEVENT_VERSION}-stable"

  echo "Configuring libevent..."
  ./configure --prefix="$install_path" --disable-shared || error_exit "Failed to configure libevent"

  echo "Building libevent..."
  make -j"${ASDF_CONCURRENCY:-1}" || error_exit "Failed to build libevent"

  echo "Installing libevent..."
  make install || error_exit "Failed to install libevent"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  # Create a temporary directory for building
  local build_dir
  build_dir="$(mktemp -d)"
  trap 'rm -rf "$build_dir"' EXIT

  # Install libevent first
  install_libevent "$install_path" "$build_dir"

  # Now compile tmux
  cd "$download_path/tmux-${version}"

  echo "Running autogen for tmux..."
  ./autogen.sh || error_exit "Failed to run autogen.sh"

  echo "Configuring tmux..."
  ./configure --prefix="$install_path" \
    CFLAGS="-I${install_path}/include" \
    LDFLAGS="-L${install_path}/lib -Wl,-rpath,${install_path}/lib" \
    || error_exit "Failed to configure tmux"

  echo "Building tmux..."
  make -j"${ASDF_CONCURRENCY:-1}" || error_exit "Failed to build tmux"

  echo "Installing tmux..."
  make install || error_exit "Failed to install tmux"

  echo "Installed tmux to $install_path/bin/tmux"
}
