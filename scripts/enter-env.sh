#!/usr/bin/env bash
##
# Copyright (c) 2025 Sebastiano Trombetta
# SPDX-License-Identifier: MIT
# Licensed under the MIT License. See LICENSE file for details.
##
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${TARGET:-x86_64-bugleos-linux-musl}"
TOOLCHAIN_DIR="${TOOLCHAIN_DIR:-$ROOT_DIR/out/toolchain/$TARGET}"
SYSROOT="${SYSROOT:-$ROOT_DIR/out/sysroot/$TARGET}"

export TARGET SYSROOT TOOLCHAIN_DIR
export PATH="$TOOLCHAIN_DIR/bin:$PATH"

cat <<EOM
BugleOS toolchain environment loaded.
TARGET=$TARGET
SYSROOT=$SYSROOT
TOOLCHAIN_DIR=$TOOLCHAIN_DIR
PATH=$PATH
EOM
