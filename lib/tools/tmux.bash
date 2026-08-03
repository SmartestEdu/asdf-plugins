#!/usr/bin/env bash

# tmux - Terminal multiplexer
# Repository: https://github.com/tmux/tmux

set -euo pipefail

readonly REPO="tmux/tmux"
readonly LIBEVENT_VERSION="2.1.12"
readonly NCURSES_VERSION="6.4"
readonly UTF8PROC_VERSION="2.9.0"

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

  # Use the release tarball rather than the git archive: it ships a
  # pre-generated ./configure, so autoconf/automake are not required.
  local url="https://github.com/${REPO}/releases/download/${version}/tmux-${version}.tar.gz"

  mkdir -p "$download_path"

  echo "Downloading tmux ${version}..."
  download_file "$url" "$download_path/tmux.tar.gz"

  echo "Extracting tmux..."
  extract_tar_gz "$download_path/tmux.tar.gz" "$download_path"
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

  # tmux links only libevent_core, which needs no openssl. Disabling it avoids
  # requiring openssl headers/pkg-config on the build host.
  echo "Configuring libevent..."
  ./configure --prefix="$install_path" \
    --disable-shared \
    --disable-openssl \
    --disable-samples \
    --disable-libevent-regress \
    || error_exit "Failed to configure libevent"

  echo "Building libevent..."
  make -j"${ASDF_CONCURRENCY:-1}" || error_exit "Failed to build libevent"

  echo "Installing libevent..."
  make install || error_exit "Failed to install libevent"
}

install_ncurses() {
  local install_path="$1"
  local tmp_dir="$2"

  echo "Building ncurses ${NCURSES_VERSION}..."

  cd "$tmp_dir"

  local ncurses_url="https://invisible-island.net/archives/ncurses/ncurses-${NCURSES_VERSION}.tar.gz"

  curl_wrapper -fsSL -o ncurses.tar.gz "$ncurses_url" || error_exit "Failed to download ncurses"
  tar -zxf ncurses.tar.gz || error_exit "Failed to extract ncurses"

  cd "ncurses-${NCURSES_VERSION}"

  echo "Configuring ncurses..."
  ./configure --prefix="$install_path" \
    --with-shared \
    --with-termlib \
    --enable-pc-files \
    --with-pkg-config-libdir="$install_path/lib/pkgconfig" \
    || error_exit "Failed to configure ncurses"

  echo "Building ncurses..."
  make -j"${ASDF_CONCURRENCY:-1}" || error_exit "Failed to build ncurses"

  echo "Installing ncurses..."
  make install || error_exit "Failed to install ncurses"
}

install_utf8proc() {
  local install_path="$1"
  local tmp_dir="$2"

  echo "Building utf8proc ${UTF8PROC_VERSION}..."

  cd "$tmp_dir"

  local utf8proc_url="https://github.com/JuliaStrings/utf8proc/archive/refs/tags/v${UTF8PROC_VERSION}.tar.gz"

  curl_wrapper -fsSL -o utf8proc.tar.gz "$utf8proc_url" || error_exit "Failed to download utf8proc"
  tar -zxf utf8proc.tar.gz || error_exit "Failed to extract utf8proc"

  cd "utf8proc-${UTF8PROC_VERSION}"

  # prefix must be set at build time too: the dylib's install_name is baked in
  # from $libdir during linking, not rewritten at install time.
  echo "Installing utf8proc..."
  make prefix="$install_path" -j"${ASDF_CONCURRENCY:-1}" || error_exit "Failed to build utf8proc"
  make prefix="$install_path" install || error_exit "Failed to install utf8proc"
}

install_tool() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"
  local install_path="$4"

  # Create a temporary directory for building
  local build_dir
  build_dir="$(mktemp -d)"
  trap "rm -rf '$build_dir'" EXIT

  # Install dependencies
  install_libevent "$install_path" "$build_dir"
  install_ncurses "$install_path" "$build_dir"
  install_utf8proc "$install_path" "$build_dir"

  # Now compile tmux
  cd "$download_path/tmux-${version}"

  # The release tarball already contains ./configure, so autogen.sh (and with it
  # autoconf/automake) is not needed. CPPFLAGS is required because pkg-config may
  # be absent, in which case configure falls back to plain header/library probes.
  echo "Configuring tmux..."
  # The utf8proc probe uses PKG_CHECK_MODULES with no fallback, so hand it the
  # flags directly rather than depending on pkg-config being installed.
  PKG_CONFIG_PATH="$install_path/lib/pkgconfig" \
  CPPFLAGS="-I$install_path/include -I$install_path/include/ncurses" \
  LDFLAGS="-L$install_path/lib -Wl,-rpath,$install_path/lib" \
  LIBUTF8PROC_CFLAGS="-I$install_path/include" \
  LIBUTF8PROC_LIBS="-L$install_path/lib -lutf8proc" \
  ./configure --prefix="$install_path" \
    --enable-utf8proc \
    || error_exit "Failed to configure tmux"

  echo "Building tmux..."
  make -j"${ASDF_CONCURRENCY:-1}" || error_exit "Failed to build tmux"

  echo "Installing tmux..."
  make install || error_exit "Failed to install tmux"

  echo "Installed tmux to $install_path/bin/tmux"
}
