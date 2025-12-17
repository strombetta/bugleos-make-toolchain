#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
TARGET="${TARGET:-x86_64-bugleos-linux-musl}"
TOOLCHAIN_ROOT="${TOOLCHAIN_ROOT:-$ROOT_DIR/out/toolchain}"
TOOLCHAIN="${TOOLCHAIN:-$TOOLCHAIN_ROOT/$TARGET}"
SYSROOT="${SYSROOT:-$TOOLCHAIN}"

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

for header in stdio.h stdlib.h unistd.h errno.h; do
  [ -f "$SYSROOT/include/$header" ] || fail "missing header: $SYSROOT/include/$header"
done

[ -f "$SYSROOT/lib/ld-musl-${TARGET%%-*}.so.1" ] || fail "missing dynamic loader: $SYSROOT/lib/ld-musl-${TARGET%%-*}.so.1"
ls "$SYSROOT/lib"/libc.so* >/dev/null 2>&1 || fail "missing libc runtime under $SYSROOT/lib"

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
