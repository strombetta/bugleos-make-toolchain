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

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
TARGET="${TARGET:-x86_64-bugleos-linux-musl}"
TOOLCHAIN_ROOT="${TOOLCHAIN_ROOT:-$ROOT_DIR/out/toolchain}"
TOOLCHAIN="${TOOLCHAIN:-$TOOLCHAIN_ROOT/$TARGET}"
SYSROOT="${SYSROOT:-$TOOLCHAIN/sysroot}"
export PATH="$TOOLCHAIN_ROOT/bin:$TOOLCHAIN_ROOT/$TARGET/bin:$PATH"

GCC_BIN="${TARGET}-gcc"
READELF_BIN="${TARGET}-readelf"

fail() {
  echo "[verify-toolchain] ERROR: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "$1 not found in PATH"
}

require_cmd "$GCC_BIN"
require_cmd "$READELF_BIN"

normalize() {
  local path="$1"
  echo "${path%/}"
}

expected_sysroot="$(normalize "$SYSROOT")"
printed_sysroot="$(normalize "$($GCC_BIN --print-sysroot)" || true)"
[ "$printed_sysroot" = "$expected_sysroot" ] || fail "gcc reports sysroot '$printed_sysroot' (expected '$expected_sysroot')"

include_root="$SYSROOT/usr/include"
if [ ! -d "$include_root" ] && [ -d "$SYSROOT/include" ]; then
  include_root="$SYSROOT/include"
fi
[ -d "$include_root" ] || fail "missing headers directory: $include_root"
for header in stdio.h stdlib.h unistd.h errno.h; do
  [ -f "$include_root/$header" ] || fail "missing header: $include_root/$header"
done

ldso="$SYSROOT/lib/ld-musl-${TARGET%%-*}.so.1"
ldso_alt="$SYSROOT/usr/lib/ld-musl-${TARGET%%-*}.so.1"
[ -e "$ldso" ] || [ -e "$ldso_alt" ] || fail "missing dynamic loader: $ldso (or $ldso_alt)"
ls "$SYSROOT/lib"/libc.so* >/dev/null 2>&1 || ls "$SYSROOT/usr/lib"/libc.so* >/dev/null 2>&1 || fail "missing libc runtime under $SYSROOT/lib or $SYSROOT/usr/lib"

for crt in crt1.o crti.o crtn.o; do
  if [ -f "$SYSROOT/lib/$crt" ]; then
    :
  elif [ -f "$SYSROOT/usr/lib/$crt" ]; then
    :
  else
    fail "missing CRT object: $crt (looked in lib/ and usr/lib/ under sysroot)"
  fi
done

trace_file=$(mktemp)
trap 'rm -f "$trace_file" "$workdir/hello" "$workdir/hello.c"; rmdir "$workdir" 2>/dev/null || true' EXIT
workdir=$(mktemp -d)

echo '#include <stdio.h>' | "$GCC_BIN" -E -v -x c - >"$trace_file" 2>&1 || fail "preprocessor trace failed"
if grep -E '^ /(usr(/local)?/include)' "$trace_file" | grep -v "$SYSROOT" >/dev/null; then
  fail "host /usr include directories detected in include search path"
fi

echo 'int main(void){return 0;}' >"$workdir/hello.c"
"$GCC_BIN" --sysroot="$SYSROOT" "$workdir/hello.c" -o "$workdir/hello" || fail "failed to build smoke test"
"$READELF_BIN" -l "$workdir/hello" | grep -q "interpreter.*ld-musl-" || fail "binary is not linked against musl interpreter"

echo "[verify-toolchain] OK for $TARGET"
