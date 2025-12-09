#!/usr/bin/env bash
##
# Copyright (c) 2025 Sebastiano Trombetta
# SPDX-License-Identifier: MIT
# Licensed under the MIT License. See LICENSE file for details.
##
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DOWNLOADS_DIR="${DOWNLOADS_DIR:-$ROOT_DIR/downloads}"

version_of() {
  local var="$1"
  awk -F':=' -v name="$var" '$1 ~ "^"name"" {gsub(/[ \t]/,"",$2); print $2}' "$ROOT_DIR/config/versions.mk"
}

url_of() {
  local var="$1"
  awk -F':=' -v name="$var" '$1 ~ "^"name"" {sub(/^ /,"",$2); print $2}' "$ROOT_DIR/config/versions.mk"
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

BINUTILS_VERSION=$(version_of BINUTILS_VERSION)
GCC_STAGE1_VERSION=$(version_of GCC_STAGE1_VERSION)
GCC_VERSION=$(version_of GCC_VERSION)
MUSL_VERSION=$(version_of MUSL_VERSION)

BINUTILS_URL=$(url_of BINUTILS_URL)
GCC_STAGE1_URL=$(url_of GCC_STAGE1_URL)
GCC_URL=$(url_of GCC_URL)
MUSL_URL=$(url_of MUSL_URL)

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

fetch "binutils-${BINUTILS_VERSION}.tar.xz" "$(expand_url "$BINUTILS_URL")"
fetch "gcc-${GCC_STAGE1_VERSION}.tar.xz" "$(expand_url "$GCC_STAGE1_URL")"
fetch "gcc-${GCC_VERSION}.tar.xz" "$(expand_url "$GCC_URL")"
fetch "musl-${MUSL_VERSION}.tar.gz" "$(expand_url "$MUSL_URL")"
