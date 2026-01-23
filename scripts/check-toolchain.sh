#!/bin/sh
set -eu

ROOT_DIR=${ROOT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}
TARGET=${TARGET:-x86_64-bugleos-linux-musl}
TOOLCHAIN_ROOT=${TOOLCHAIN_ROOT:-$ROOT_DIR/out/toolchain}
TOOLCHAIN_TARGET_DIR=${TOOLCHAIN_TARGET_DIR:-$TOOLCHAIN_ROOT/$TARGET}
SYSROOT=${SYSROOT:-$TOOLCHAIN_TARGET_DIR/sysroot}
PREFIX=${PREFIX:-$TOOLCHAIN_ROOT}

PATH="$PREFIX/bin:$TOOLCHAIN_TARGET_DIR/bin:$PATH"

fail() {
  echo "[check-toolchain] ERROR: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "$1 not found in PATH"
}

resolve_tool() {
  tool="$1"
  for dir in "$PREFIX/bin" "$TOOLCHAIN_TARGET_DIR/bin"; do
    candidate="$dir/$TARGET-$tool"
    if [ -x "$candidate" ]; then
      printf "%s\n" "$candidate"
      return 0
    fi
  done
  return 1
}

normalize() {
  printf "%s" "${1%/}"
}

TARGET_ARCH=${TARGET%%-*}
[ -n "$TARGET_ARCH" ] || fail "unable to determine target architecture from TARGET=$TARGET"

case "$TARGET_ARCH" in
  x86_64)
    EXPECTED_MACHINE="Advanced Micro Devices X86-64"
    ;;
  aarch64)
    EXPECTED_MACHINE="AArch64"
    ;;
  *)
    fail "unsupported target architecture for ELF validation: $TARGET_ARCH"
    ;;
esac

case "$(normalize "$SYSROOT")" in
  ""|"/")
    fail "unsafe sysroot path: $SYSROOT"
    ;;
esac

[ -d "$SYSROOT" ] || fail "missing sysroot directory: $SYSROOT"

for tool in gcc ld as ar ranlib strip readelf; do
  tool_path="$(resolve_tool "$tool")" || tool_path=""
  [ -n "$tool_path" ] || fail "missing toolchain binary: $TARGET-$tool (searched $PREFIX/bin and $TOOLCHAIN_TARGET_DIR/bin)"
done

require_cmd "$TARGET-gcc"
require_cmd "$TARGET-readelf"

DUMPMACHINE=$("$TARGET"-gcc -dumpmachine 2>/dev/null || true)
[ "$DUMPMACHINE" = "$TARGET" ] || fail "gcc -dumpmachine returned '$DUMPMACHINE' (expected '$TARGET')"

if ! "$TARGET"-gcc -v 2>&1 | grep -F "Target: $TARGET" >/dev/null; then
  fail "gcc -v does not report Target: $TARGET"
fi

EXPECTED_SYSROOT=$(normalize "$SYSROOT")
PRINTED_SYSROOT=$(normalize "$("$TARGET"-gcc --print-sysroot 2>/dev/null || true)")
[ "$PRINTED_SYSROOT" = "$EXPECTED_SYSROOT" ] || fail "gcc --print-sysroot returned '$PRINTED_SYSROOT' (expected '$EXPECTED_SYSROOT')"

for dir in "$SYSROOT/usr/include" "$SYSROOT/usr/lib" "$SYSROOT/lib"; do
  [ -d "$dir" ] || fail "missing sysroot directory: $dir"
done

KERNEL_HEADER=""
if [ -f "$SYSROOT/usr/include/linux/version.h" ]; then
  KERNEL_HEADER="$SYSROOT/usr/include/linux/version.h"
elif [ -f "$SYSROOT/usr/include/linux/utsrelease.h" ]; then
  KERNEL_HEADER="$SYSROOT/usr/include/linux/utsrelease.h"
fi
[ -n "$KERNEL_HEADER" ] || fail "missing kernel headers under $SYSROOT/usr/include/linux"

ldso_name="ld-musl-${TARGET_ARCH}.so.1"
ldso_path=""
if [ -e "$SYSROOT/lib/$ldso_name" ]; then
  ldso_path="$SYSROOT/lib/$ldso_name"
elif [ -e "$SYSROOT/usr/lib/$ldso_name" ]; then
  ldso_path="$SYSROOT/usr/lib/$ldso_name"
else
  for candidate in "$SYSROOT/lib"/ld-musl-*.so.1 "$SYSROOT/usr/lib"/ld-musl-*.so.1; do
    if [ -e "$candidate" ]; then
      ldso_path="$candidate"
      break
    fi
  done
fi
[ -n "$ldso_path" ] || fail "missing musl loader (expected $SYSROOT/lib/$ldso_name or $SYSROOT/usr/lib/$ldso_name)"

libc_path=""
for candidate in "$SYSROOT/lib/libc.so" "$SYSROOT/usr/lib/libc.so" "$SYSROOT/lib/libc.a" "$SYSROOT/usr/lib/libc.a"; do
  if [ -e "$candidate" ]; then
    libc_path="$candidate"
    break
  fi
done
[ -n "$libc_path" ] || fail "missing musl libc artifact under $SYSROOT/lib or $SYSROOT/usr/lib"

TARGET_BIN_DIR="$PREFIX/$TARGET/bin"
if [ -d "$TARGET_BIN_DIR" ]; then
  if [ -z "$(ls "$TARGET_BIN_DIR")" ]; then
    fail "target bin directory is empty: $TARGET_BIN_DIR"
  fi
fi

if ! LC_ALL=C "$TARGET"-readelf -h "$ldso_path" 2>/dev/null | grep -F "Machine:" | grep -F "$EXPECTED_MACHINE" >/dev/null; then
  fail "unexpected ELF machine for $ldso_path (expected $EXPECTED_MACHINE)"
fi

echo "[OK] $TARGET_ARCH: gcc, binutils, sysroot, musl, kernel headers"
