#!/usr/bin/env bash
##
# Copyright (c) 2025 Sebastiano Trombetta
# SPDX-License-Identifier: MIT
# Licensed under the MIT License. See LICENSE file for details.
##
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${TARGET:-x86_64-bugleos-linux-musl}"
TOOLCHAIN_ROOT="${TOOLCHAIN_ROOT:-$ROOT_DIR/out/toolchain}"
TOOLCHAIN="${TOOLCHAIN:-$TOOLCHAIN_ROOT/$TARGET}"
SYSROOT="${SYSROOT:-$TOOLCHAIN/sysroot}"

export TARGET SYSROOT TOOLCHAIN_ROOT TOOLCHAIN
export PATH="$TOOLCHAIN_ROOT/bin:$TOOLCHAIN_ROOT/$TARGET/bin:$PATH"

cat <<EOM
BugleOS toolchain environment loaded.
TARGET=$TARGET
SYSROOT=$SYSROOT
TOOLCHAIN_ROOT=$TOOLCHAIN_ROOT
TOOLCHAIN=$TOOLCHAIN
PATH=$PATH
EOM
