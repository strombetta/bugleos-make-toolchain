#!/usr/bin/env bash
##
# Copyright (c) 2025 Sebastiano Trombetta
# SPDX-License-Identifier: MIT
# Licensed under the MIT License. See LICENSE file for details.
##
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
TARGET="${TARGET:-x86_64-bugleos-linux-musl}"
SYSROOT="${SYSROOT:-$ROOT_DIR/out/sysroot/$TARGET}"
TOOLCHAIN="${TOOLCHAIN:-$ROOT_DIR/out/toolchain/$TARGET}"
VERSIONS_MK="$ROOT_DIR/config/versions.mk"

version_of() {
  local var="$1"
  awk -F':=' -v name="$var" '$1 ~ "^"name"" {gsub(/[ \t]/,"",$2); print $2}' "$VERSIONS_MK"
}

BINUTILS_VERSION=$(version_of BINUTILS_VERSION)
GCC_STAGE1_VERSION=$(version_of GCC_STAGE1_VERSION)
GCC_VERSION=$(version_of GCC_VERSION)
MUSL_VERSION=$(version_of MUSL_VERSION)

mkdir -p "$TOOLCHAIN"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_HASH=$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")

ENV_FILE="$TOOLCHAIN/bugleos-toolchain.env"
JSON_FILE="$TOOLCHAIN/bugleos-toolchain.json"

cat > "$ENV_FILE" <<EOF_ENV
# Generated BugleOS toolchain environment
export TARGET="$TARGET"
export SYSROOT="$SYSROOT"
export TOOLCHAIN="$TOOLCHAIN"
export PATH="$TOOLCHAIN/bin:${PATH}"

export BUGLEOS_BINUTILS_VERSION="$BINUTILS_VERSION"
export BUGLEOS_GCC_STAGE1_VERSION="$GCC_STAGE1_VERSION"
export BUGLEOS_GCC_VERSION="$GCC_VERSION"
export BUGLEOS_MUSL_VERSION="$MUSL_VERSION"
export BUGLEOS_TOOLCHAIN_BUILD="$TIMESTAMP"
export BUGLEOS_TOOLCHAIN_GIT="$GIT_HASH"
EOF_ENV

cat > "$JSON_FILE" <<EOF_JSON
{
  "target": "$TARGET",
  "sysroot": "$SYSROOT",
  "toolchain_dir": "$TOOLCHAIN",
  "binutils_version": "$BINUTILS_VERSION",
  "gcc_stage1_version": "$GCC_STAGE1_VERSION",
  "gcc_version": "$GCC_VERSION",
  "musl_version": "$MUSL_VERSION",
  "build_timestamp": "$TIMESTAMP",
  "git_commit": "$GIT_HASH"
}
EOF_JSON

echo "Metadata written to $ENV_FILE and $JSON_FILE"
