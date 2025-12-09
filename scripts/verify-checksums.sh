#!/usr/bin/env bash
##
# Copyright (c) 2025 Sebastiano Trombetta
# SPDX-License-Identifier: MIT
# Licensed under the MIT License. See LICENSE file for details.
##
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DOWNLOADS_DIR="${DOWNLOADS_DIR:-$ROOT_DIR/downloads}"

sha_of() {
  local var="$1"
  awk -F':=' -v name="$var" '$1 ~ "^"name"" {gsub(/[ \t]/,"",$2); print $2}' "$ROOT_DIR/config/versions.mk"
}

BINUTILS_VERSION=$(sha_of BINUTILS_VERSION)
GCC_STAGE1_VERSION=$(sha_of GCC_STAGE1_VERSION)
GCC_VERSION=$(sha_of GCC_VERSION)
MUSL_VERSION=$(sha_of MUSL_VERSION)

BINUTILS_SHA=$(sha_of BINUTILS_SHA256)
GCC_STAGE1_SHA=$(sha_of GCC_STAGE1_SHA256)
GCC_SHA=$(sha_of GCC_SHA256)
MUSL_SHA=$(sha_of MUSL_SHA256)

ensure_checksum_set() {
  local name="$1"
  local value="$2"

  if [[ $value =~ ^SHA256_PLACEHOLDER ]]; then
    echo "Checksum for $name is missing. Please update config/versions.mk with the real SHA256 before verifying." >&2
    exit 1
  fi
}

ensure_checksum_set "binutils" "$BINUTILS_SHA"
ensure_checksum_set "GCC (stage1)" "$GCC_STAGE1_SHA"
ensure_checksum_set "GCC" "$GCC_SHA"
ensure_checksum_set "musl" "$MUSL_SHA"

cat > "$DOWNLOADS_DIR/.checksums" <<EOF_SUMS
$BINUTILS_SHA  binutils-${BINUTILS_VERSION}.tar.xz
$GCC_STAGE1_SHA  gcc-${GCC_STAGE1_VERSION}.tar.xz
$GCC_SHA  gcc-${GCC_VERSION}.tar.xz
$MUSL_SHA  musl-${MUSL_VERSION}.tar.gz
EOF_SUMS

( cd "$DOWNLOADS_DIR" && sha256sum --quiet -c .checksums )
echo "All checksums verified."
