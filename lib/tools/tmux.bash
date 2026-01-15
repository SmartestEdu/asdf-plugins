#!/usr/bin/env bash

# tmux - Terminal multiplexer
# Repository: https://github.com/tmux/tmux

set -euo pipefail

readonly REPO="tmux/tmux"

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

  # tmux needs to be compiled from source
  local url="https://github.com/${REPO}/releases/download/${version}/tmux-${version}.tar.gz"

  mkdir -p "$download_path"
  download_file "$url" "$download_path/tmux.tar.gz"
  extract_tar_gz "$download_path/tmux.tar.gz" "$download_path"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  # Check for required dependencies
  if ! command_exists pkg-config; then
    echo "Warning: pkg-config not found. Install it for proper tmux compilation."
  fi

  # Compile tmux from source
  cd "$download_path/tmux-${version}"

  echo "Configuring tmux..."
  ./configure --prefix="$install_path" || error_exit "Failed to configure tmux"

  echo "Building tmux..."
  make || error_exit "Failed to build tmux"

  echo "Installing tmux..."
  make install || error_exit "Failed to install tmux"

  echo "Installed tmux to $install_path/bin/tmux"
}
