#!/usr/bin/env bash

# ast-grep (sg) - A fast and polyglot tool for code searching, linting, rewriting at scale.
# Repository: https://github.com/ast-grep/ast-grep

set -euo pipefail

readonly REPO="ast-grep/ast-grep"

list_all_versions() {
  list_github_versions "$REPO" | sort_versions | tr '\n' ' '
}

get_target() {
  local os arch

  os="$(get_os)"
  arch="$(get_arch)"

  case "${os}_${arch}" in
    linux_amd64)  echo "x86_64-unknown-linux-gnu" ;;
    linux_arm64)  echo "aarch64-unknown-linux-gnu" ;;
    darwin_amd64) echo "x86_64-apple-darwin" ;;
    darwin_arm64) echo "aarch64-apple-darwin" ;;
    *) error_exit "ast-grep does not support platform: ${os}_${arch}" ;;
  esac
}

get_download_url() {
  local version="$1"
  local target
  target="$(get_target)"

  # Release assets are in format: app-<target>.zip
  # Note: The version in the tag usually has 'v' prefix, but list_github_versions removes it.
  # If the tag is v0.41.1, the download URL is:
  # https://github.com/ast-grep/ast-grep/releases/download/v0.41.1/app-x86_64-unknown-linux-gnu.zip
  echo "https://github.com/${REPO}/releases/download/v${version}/app-${target}.zip"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "ast-grep only supports version installs, not ref installs"
  fi

  local url
  url="$(get_download_url "$version")"

  mkdir -p "$download_path"
  download_file "$url" "$download_path/ast-grep.zip"
  extract_zip "$download_path/ast-grep.zip" "$download_path"
  
  # The zip contains both 'sg' and 'ast-grep' binaries.
  # We will install 'sg' as the primary binary, but also 'ast-grep' since it's the tool's name.
  mkdir -p "$download_path/bin"
  if [ -f "$download_path/sg" ]; then
    mv "$download_path/sg" "$download_path/bin/"
    mv "$download_path/ast-grep" "$download_path/bin/"
  else
    error_exit "Could not find 'sg' binary in extracted archive"
  fi
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  mkdir -p "$install_path/bin"
  install_binary "$download_path/bin/sg" "$install_path/bin/sg" "ast-grep (sg)"
  install_binary "$download_path/bin/ast-grep" "$install_path/bin/ast-grep" "ast-grep"
}
