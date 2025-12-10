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

sha_of() {
  local var="$1"
  awk -F':=' -v name="$var" '$1 ~ "^"name"" {gsub(/[ \t]/,"",$2); print $2}' "$ROOT_DIR/config/versions.mk"
}

BINUTILS_VERSION=$(sha_of BINUTILS_VERSION)
GCC_VERSION=$(sha_of GCC_VERSION)
MUSL_VERSION=$(sha_of MUSL_VERSION)

BINUTILS_SHA=$(sha_of BINUTILS_SHA256)
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
ensure_checksum_set "GCC" "$GCC_SHA"
ensure_checksum_set "musl" "$MUSL_SHA"

SIG_BINUTILS="binutils-${BINUTILS_VERSION}.tar.xz.sig"
SIG_GCC="gcc-${GCC_VERSION}.tar.xz.sig"
SIG_MUSL="musl-${MUSL_VERSION}.tar.gz.asc"

GNU_KEYRING="$DOWNLOADS_DIR/gnu-keyring.gpg"
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

for signature in \
  "$DOWNLOADS_DIR/$SIG_BINUTILS" \
  "$DOWNLOADS_DIR/$SIG_GCC" \
  "$DOWNLOADS_DIR/$SIG_MUSL"; do
  ensure_file_present "$signature" "signature file"
done

ensure_file_present "$GNU_KEYRING" "GNU project keyring"
ensure_file_present "$MUSL_PUBKEY" "musl public key"

for archive in \
  "$DOWNLOADS_DIR/binutils-${BINUTILS_VERSION}.tar.xz" \
  "$DOWNLOADS_DIR/gcc-${GCC_VERSION}.tar.xz" \
  "$DOWNLOADS_DIR/musl-${MUSL_VERSION}.tar.gz"; do
  ensure_file_present "$archive" "source archive"
done

GNUPGHOME_TMP=$(mktemp -d)
cleanup() {
  rm -rf "$GNUPGHOME_TMP"
}
trap cleanup EXIT

gpg_common_args=(--homedir "$GNUPGHOME_TMP" --batch --no-tty)

gpg "${gpg_common_args[@]}" --import "$GNU_KEYRING" >/dev/null
gpg "${gpg_common_args[@]}" --import "$MUSL_PUBKEY" >/dev/null

verify_signature() {
  local sig_file="$1" target_file="$2"
  gpg "${gpg_common_args[@]}" --verify "$DOWNLOADS_DIR/$sig_file" "$DOWNLOADS_DIR/$target_file"
}

echo "Verifying PGP signatures..."
verify_signature "$SIG_BINUTILS" "binutils-${BINUTILS_VERSION}.tar.xz"
verify_signature "$SIG_GCC" "gcc-${GCC_VERSION}.tar.xz"
verify_signature "$SIG_MUSL" "musl-${MUSL_VERSION}.tar.gz"
echo "All signatures verified."

cat > "$DOWNLOADS_DIR/.checksums" <<EOF_SUMS
$BINUTILS_SHA  binutils-${BINUTILS_VERSION}.tar.xz
$GCC_SHA  gcc-${GCC_VERSION}.tar.xz
$MUSL_SHA  musl-${MUSL_VERSION}.tar.gz
EOF_SUMS

( cd "$DOWNLOADS_DIR" && sha256sum --quiet -c .checksums )
echo "All checksums verified."
