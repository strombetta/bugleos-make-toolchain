#!/usr/bin/env bash
# Copyright (c) 2025 Sebastiano Trombetta
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DOWNLOADS_DIR="${DOWNLOADS_DIR:-$ROOT_DIR/downloads}"

value_of() {
  local var="$1"
  awk -F':=' -v name="$var" '$1 ~ "^"name"" {gsub(/[ \t]/,"",$2); print $2}' "$ROOT_DIR/config/versions.mk"
}

BINUTILS_VERSION=$(value_of BINUTILS_VERSION)
GCC_VERSION=$(value_of GCC_VERSION)
MUSL_VERSION=$(value_of MUSL_VERSION)
LINUX_VERSION=$(value_of LINUX_VERSION)

BINUTILS_SHA=$(value_of BINUTILS_SHA256)
GCC_SHA=$(value_of GCC_SHA256)
MUSL_SHA=$(value_of MUSL_SHA256)
LINUX_SHA=$(value_of LINUX_SHA256)
LINUX_KEYRING_FPRS=$(value_of LINUX_KEYRING_FPRS)
GNU_KEYRING_FPRS=$(value_of GNU_KEYRING_FPRS)
MUSL_PUBKEY_FPR=$(value_of MUSL_PUBKEY_FPR)

ensure_checksum_set() {
  local name="$1"
  local value="$2"

  if [[ $value =~ ^SHA256_PLACEHOLDER ]]; then
    echo "Checksum for $name is missing. Please update config/versions.mk with the real SHA256 before verifying." >&2
    exit 1
  fi
}

ensure_fpr_set() {
  local name="$1"
  local value="$2"

  if [[ -z "$value" || $value =~ FPR_PLACEHOLDER ]]; then
    echo "Fingerprint for $name is missing. Please update config/versions.mk before verifying." >&2
    exit 1
  fi
}

normalize_fpr() {
  printf '%s' "$1" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]'
}

extract_fprs() {
  local key_file="$1"
  gpg --with-colons --fingerprint --show-keys "$key_file" | awk -F: '$1 == "fpr" {print $10}'
}

verify_key_fprs() {
  local key_file="$1"
  local expected_list="$2"
  local label="$3"
  local found expected normalized_expected expected_items

  expected_items=$(printf '%s' "$expected_list" | tr ',' ' ')

  for expected in $expected_items; do
    if [[ -z "$expected" ]]; then
      continue
    fi
    normalized_expected=$(normalize_fpr "$expected")
    found=0
    while IFS= read -r fpr; do
      if [ "$(normalize_fpr "$fpr")" = "$normalized_expected" ]; then
        found=1
        break
      fi
    done < <(extract_fprs "$key_file")

    if [ "$found" -ne 1 ]; then
      echo "Expected fingerprint not found for $label: $expected" >&2
      exit 1
    fi
  done
}

SIG_BINUTILS="binutils-${BINUTILS_VERSION}.tar.xz.sig"
SIG_LINUX="linux-${LINUX_VERSION}.tar.sign"
SIG_GCC="gcc-${GCC_VERSION}.tar.xz.sig"
SIG_MUSL="musl-${MUSL_VERSION}.tar.gz.asc"

GNU_KEYRING="$DOWNLOADS_DIR/gnu-keyring.gpg"
LINUX_KEYRING="$DOWNLOADS_DIR/linux-keyring.gpg"
MUSL_PUBKEY="$DOWNLOADS_DIR/musl.pub"

ensure_file_present() {
  local path="$1"
  local description="$2"
  if [[ ! -f "$path" ]]; then
    cat >&2 <<EOF
Missing $description at $path
Please run scripts/fetch-sources.sh to download the source archives, their signatures, and the required keyrings.
EOF
    exit 1
  fi
}

GNUPGHOME_TMP=$(mktemp -d)
cleanup() {
  rm -rf "$GNUPGHOME_TMP"
}
trap cleanup EXIT

gpg_common_args=(--homedir "$GNUPGHOME_TMP" --batch --no-tty)

import_gnu_keyring() {
  ensure_file_present "$GNU_KEYRING" "GNU project keyring"
  ensure_fpr_set "GNU_KEYRING_FPRS" "$GNU_KEYRING_FPRS"
  verify_key_fprs "$GNU_KEYRING" "$GNU_KEYRING_FPRS" "GNU keyring"
  gpg "${gpg_common_args[@]}" --import "$GNU_KEYRING" >/dev/null
}

import_linux_keyring() {
  ensure_file_present "$LINUX_KEYRING" "Linux kernel signing keyring"
  ensure_fpr_set "LINUX_KEYRING_FPRS" "$LINUX_KEYRING_FPRS"
  verify_key_fprs "$LINUX_KEYRING" "$LINUX_KEYRING_FPRS" "Linux kernel signing keyring"
  gpg "${gpg_common_args[@]}" --import "$LINUX_KEYRING" >/dev/null
}

import_musl_pubkey() {
  ensure_file_present "$MUSL_PUBKEY" "musl public key"
  ensure_fpr_set "MUSL_PUBKEY_FPR" "$MUSL_PUBKEY_FPR"
  verify_key_fprs "$MUSL_PUBKEY" "$MUSL_PUBKEY_FPR" "musl public key"
  gpg "${gpg_common_args[@]}" --import "$MUSL_PUBKEY" >/dev/null
}

verify_signature() {
  local sig_file="$1" target_file="$2"
  gpg "${gpg_common_args[@]}" --verify "$DOWNLOADS_DIR/$sig_file" "$DOWNLOADS_DIR/$target_file"
}

verify_checksum() {
  local checksum="$1" archive="$2"
  ( cd "$DOWNLOADS_DIR" && printf '%s  %s\n' "$checksum" "$archive" | sha256sum --quiet -c - )
}

verify_binutils() {
  ensure_checksum_set "binutils" "$BINUTILS_SHA"
  ensure_file_present "$DOWNLOADS_DIR/$SIG_BINUTILS" "binutils signature file"
  ensure_file_present "$DOWNLOADS_DIR/binutils-${BINUTILS_VERSION}.tar.xz" "binutils source archive"
  import_gnu_keyring
  echo "Verifying binutils signature..."
  verify_signature "$SIG_BINUTILS" "binutils-${BINUTILS_VERSION}.tar.xz"
  echo "Verifying binutils checksum..."
  verify_checksum "$BINUTILS_SHA" "binutils-${BINUTILS_VERSION}.tar.xz"
}

verify_linux() {
  ensure_checksum_set "linux" "$LINUX_SHA"
  ensure_file_present "$DOWNLOADS_DIR/$SIG_LINUX" "Linux headers signature file"
  ensure_file_present "$DOWNLOADS_DIR/linux-${LINUX_VERSION}.tar.gz" "linux source archive"
  import_linux_keyring
  echo "Verifying Linux headers signature..."
  verify_signature "$SIG_LINUX" "linux-${LINUX_VERSION}.tar.gz"
  echo "Verifying Linux headers checksum..."
  verify_checksum "$LINUX_SHA" "linux-${LINUX_VERSION}.tar.gz"
}

verify_gcc() {
  ensure_checksum_set "GCC" "$GCC_SHA"
  ensure_file_present "$DOWNLOADS_DIR/$SIG_GCC" "GCC signature file"
  ensure_file_present "$DOWNLOADS_DIR/gcc-${GCC_VERSION}.tar.xz" "GCC source archive"
  import_gnu_keyring
  echo "Verifying GCC signature..."
  verify_signature "$SIG_GCC" "gcc-${GCC_VERSION}.tar.xz"
  echo "Verifying GCC checksum..."
  verify_checksum "$GCC_SHA" "gcc-${GCC_VERSION}.tar.xz"
}

verify_musl() {
  ensure_checksum_set "musl" "$MUSL_SHA"
  ensure_file_present "$DOWNLOADS_DIR/$SIG_MUSL" "musl signature file"
  ensure_file_present "$DOWNLOADS_DIR/musl-${MUSL_VERSION}.tar.gz" "musl source archive"
  import_musl_pubkey
  echo "Verifying musl signature..."
  verify_signature "$SIG_MUSL" "musl-${MUSL_VERSION}.tar.gz"
  echo "Verifying musl checksum..."
  verify_checksum "$MUSL_SHA" "musl-${MUSL_VERSION}.tar.gz"
}

verify_all() {
  verify_binutils
  verify_linux
  verify_gcc
  verify_musl
}

if [[ $# -eq 0 ]]; then
  set -- binutils gcc musl
fi

for component in "$@"; do
  case "$component" in
    binutils) verify_binutils ;;
    gcc) verify_gcc ;;
    musl) verify_musl ;;
    linux) verify_linux ;;
    all) verify_all ;;
    *) echo "Unknown component: $component" >&2; exit 1 ;;
  esac
done
