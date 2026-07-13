#!/usr/bin/env bash

# tsgolint - type-aware linting binary used by oxlint --type-aware.
# Repository: https://github.com/robinnagpal-newsela/oxlint-tsgolint
#
# Release tags are date-based, e.g. "v2026.06.24". Assets are raw (unarchived)
# binaries named "tsgolint-<os>-<arch>" where os is linux/darwin and arch is
# amd64/arm64 (there is no tarball/zip to extract).
#
# Note: oxlint does NOT discover tsgolint on PATH. It uses the
# OXLINT_TSGOLINT_PATH env var (falling back to the binary bundled in the
# oxlint-tsgolint npm package). After installing, export OXLINT_TSGOLINT_PATH
# to point at this binary so `oxlint --type-aware` uses it:
#   export OXLINT_TSGOLINT_PATH="$(asdf where tsgolint)/bin/tsgolint"

set -euo pipefail

readonly REPO="robinnagpal-newsela/oxlint-tsgolint"

list_all_versions() {
  # Tags look like "v2026.06.24" (date-based, not semver). list_github_versions
  # already strips the leading "v", so keep dotted-numeric entries and sort.
  list_github_versions "$REPO" |
    grep -E '^[0-9]+(\.[0-9]+)+$' |
    sort_versions |
    tr '\n' ' '
}

# Map the current platform to tsgolint's <os>-<arch> asset naming.
get_target() {
  local os arch
  os="$(get_os)"
  arch="$(get_arch)"
  case "${os}_${arch}" in
    linux_amd64 | linux_arm64 | darwin_amd64 | darwin_arm64) echo "${os}-${arch}" ;;
    *) error_exit "tsgolint does not support platform: ${os}_${arch}" ;;
  esac
}

get_download_url() {
  local version="$1"
  local target
  target="$(get_target)"

  echo "https://github.com/${REPO}/releases/download/v${version}/tsgolint-${target}"
}

download_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    error_exit "tsgolint only supports version installs, not ref installs"
  fi

  local url
  url="$(get_download_url "$version")"

  # The asset is a raw binary; download it directly (no archive to extract).
  mkdir -p "$download_path/bin"
  download_file "$url" "$download_path/bin/tsgolint"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  mkdir -p "$install_path/bin"
  install_binary "${download_path}/bin/tsgolint" "${install_path}/bin/tsgolint" "tsgolint"
}
