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

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
TARGET="${TARGET:-x86_64-bugleos-linux-musl}"
TOOLCHAIN_ROOT="${TOOLCHAIN_ROOT:-$ROOT_DIR/out/toolchain}"
TOOLCHAIN="${TOOLCHAIN:-$TOOLCHAIN_ROOT/$TARGET}"
SYSROOT="${SYSROOT:-$TOOLCHAIN/sysroot}"

value_of() {
  local var="$1"
  awk -F':=' -v name="$var" '$1 ~ "^"name"" {gsub(/[ \t]/,"",$2); print $2}' "$ROOT_DIR/config/versions.mk"
}

BINUTILS_VERSION=$(value_of BINUTILS_VERSION)
GCC_VERSION=$(value_of GCC_VERSION)
MUSL_VERSION=$(value_of MUSL_VERSION)
LINUX_VERSION=$(value_of LINUX_VERSION)

build_timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
git_rev=""
if command -v git >/dev/null 2>&1; then
  git_rev=$(git -C "$ROOT_DIR" rev-parse HEAD 2>/dev/null || true)
fi

mkdir -p "$TOOLCHAIN"

env_file="$TOOLCHAIN/bugleos-toolchain.env"
cat > "$env_file" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

toolchain_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
toolchain_root="$(cd "$toolchain_dir/.." && pwd)"
target_name="$(basename "$toolchain_dir")"

export TARGET="$target_name"
export TOOLCHAIN_ROOT="$toolchain_root"
export TOOLCHAIN="$toolchain_dir"
export SYSROOT="$toolchain_dir/sysroot"
export PATH="$TOOLCHAIN_ROOT/bin:$TOOLCHAIN/bin:$PATH"

unset toolchain_dir toolchain_root target_name
EOF

metadata_file="$TOOLCHAIN/toolchain-metadata.json"
cat > "$metadata_file" <<EOF
{
  "target": "$TARGET",
  "components": {
    "binutils": "$BINUTILS_VERSION",
    "gcc": "$GCC_VERSION",
    "musl": "$MUSL_VERSION",
    "linux_headers": "$LINUX_VERSION"
  },
  "build": {
    "timestamp": "$build_timestamp",
    "git": "$git_rev"
  },
  "sysroot": "$SYSROOT"
}
EOF

chmod 0644 "$env_file" "$metadata_file"
