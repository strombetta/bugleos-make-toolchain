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
