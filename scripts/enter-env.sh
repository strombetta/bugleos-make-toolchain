#!/usr/bin/env bash
##
# Copyright (c) 2025 Sebastiano Trombetta
# SPDX-License-Identifier: MIT
# Licensed under the MIT License. See LICENSE file for details.
##
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${TARGET:-x86_64-bugleos-linux-musl}"
TOOLCHAIN="${TOOLCHAIN:-$ROOT_DIR/out/toolchain/$TARGET}"
SYSROOT="${SYSROOT:-$ROOT_DIR/out/sysroot/$TARGET}"

export TARGET SYSROOT TOOLCHAIN
export PATH="$TOOLCHAIN/bin:$PATH"

cat <<EOM
BugleOS toolchain environment loaded.
TARGET=$TARGET
SYSROOT=$SYSROOT
TOOLCHAIN=$TOOLCHAIN
PATH=$PATH
EOM
