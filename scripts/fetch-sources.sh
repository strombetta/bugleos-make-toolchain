#!/usr/bin/env bash
#
# Copyright (c) Sebastiano Trombetta. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DOWNLOADS_DIR="${DOWNLOADS_DIR:-$ROOT_DIR/downloads}"

value_of() {
  local mk_file="$1"
  local var="$2"
  awk -F':=' -v name="$var" '$1 ~ "^"name"" {sub(/^[ \t]+/,"",$2); print $2; exit}' "$mk_file"
}

expand_make_vars() {
  # Translate make-style $(VAR) placeholders into shell-style ${VAR} for safe expansion.
  sed -E 's/\$\(([^)]*)\)/${\1}/g'
}

expand_url() {
  local template="$1"
  local shell_template
  shell_template=$(printf '%s' "$template" | expand_make_vars)
  eval "echo \"$shell_template\""
}

fetch() {
  local name="$1" url="$2"
  local dest="$DOWNLOADS_DIR/$name"
  if [[ -f "$dest" ]]; then
    echo "[fetch] $name already present, skipping"
    return 0
  fi
  echo "[fetch] Downloading $name"
  mkdir -p "$DOWNLOADS_DIR"
  if command -v wget >/dev/null 2>&1; then
    wget -c -O "$dest" "$url"
  elif command -v curl >/dev/null 2>&1; then
    curl -L -C - -o "$dest" "$url"
  else
    echo "No downloader (wget/curl) available" >&2
    exit 1
  fi
}

BINUTILS_MK="$ROOT_DIR/make/binutils-stage1.mk"
LINUX_MK="$ROOT_DIR/make/linux-headers.mk"
GCC_MK="$ROOT_DIR/make/gcc-stage1.mk"
MUSL_MK="$ROOT_DIR/make/musl.mk"

BINUTILS_VERSION=$(value_of "$BINUTILS_MK" BINUTILS_VERSION)
LINUX_VERSION=$(value_of "$LINUX_MK" LINUX_VERSION)
GCC_VERSION=$(value_of "$GCC_MK" GCC_VERSION)
MUSL_VERSION=$(value_of "$MUSL_MK" MUSL_VERSION)

BINUTILS_URL=$(value_of "$BINUTILS_MK" BINUTILS_URL)
BINUTILS_SIG_URL=$(value_of "$BINUTILS_MK" BINUTILS_SIG_URL)
LINUX_URL=$(value_of "$LINUX_MK" LINUX_URL)
LINUX_SIG_URL=$(value_of "$LINUX_MK" LINUX_SIG_URL)
GCC_URL=$(value_of "$GCC_MK" GCC_URL)
GCC_SIG_URL=$(value_of "$GCC_MK" GCC_SIG_URL)
MUSL_URL=$(value_of "$MUSL_MK" MUSL_URL)
MUSL_SIG_URL=$(value_of "$MUSL_MK" MUSL_SIG_URL)
MUSL_PUBKEY_URL=$(value_of "$MUSL_MK" MUSL_PUBKEY_URL)

fetch_binutils() {
  local gnu_keyring_url
  gnu_keyring_url=$(value_of "$BINUTILS_MK" GNU_KEYRING_URL)
  fetch "binutils-${BINUTILS_VERSION}.tar.xz" "$(expand_url "$BINUTILS_URL")"
  fetch "binutils-${BINUTILS_VERSION}.tar.xz.sig" "$(expand_url "$BINUTILS_SIG_URL")"
  fetch "gnu-keyring.gpg" "$(expand_url "$gnu_keyring_url")"
}

fetch_linux() {
  fetch "linux-${LINUX_VERSION}.tar.xz" "$(expand_url "$LINUX_URL")"
  fetch "linux-${LINUX_VERSION}.tar.sign" "$(expand_url "$LINUX_SIG_URL")"
}

fetch_gcc() {
  local gnu_keyring_url
  gnu_keyring_url=$(value_of "$GCC_MK" GNU_KEYRING_URL)
  fetch "gcc-${GCC_VERSION}.tar.xz" "$(expand_url "$GCC_URL")"
  fetch "gcc-${GCC_VERSION}.tar.xz.sig" "$(expand_url "$GCC_SIG_URL")"
  fetch "gnu-keyring.gpg" "$(expand_url "$gnu_keyring_url")"
}

fetch_musl() {
  fetch "musl-${MUSL_VERSION}.tar.gz" "$(expand_url "$MUSL_URL")"
  fetch "musl-${MUSL_VERSION}.tar.gz.asc" "$(expand_url "$MUSL_SIG_URL")"
  fetch "musl.pub" "$(expand_url "$MUSL_PUBKEY_URL")"
}

fetch_all() {
  fetch_binutils
  fetch_linux
  fetch_gcc
  fetch_musl
}

if [[ $# -eq 0 ]]; then
  set -- binutils linux gcc musl
fi

for component in "$@"; do
  case "$component" in
    binutils) fetch_binutils ;;
    gcc) fetch_gcc ;;
    musl) fetch_musl ;;
    linux) fetch_linux ;;
    all) fetch_all ;;
    *) echo "Unknown component: $component" >&2; exit 1 ;;
  esac
done
