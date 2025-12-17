#
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

ROOT_DIR ?= $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
DOWNLOADS_DIR ?= $(ROOT_DIR)/downloads
SOURCES_DIR ?= $(ROOT_DIR)/sources
BUILDS_DIR ?= $(ROOT_DIR)/builds
OUT_DIR ?= $(ROOT_DIR)/out
LOGS_DIR ?= $(ROOT_DIR)/logs

HOST_ARCH := $(shell uname -m)
HOST_TARGET := $(shell \
  arch="$(HOST_ARCH)"; \
  if [ "$$arch" = "x86_64" ] || [ "$$arch" = "amd64" ]; then echo x86_64-bugleos-linux-musl; \
  elif [ "$$arch" = "aarch64" ] || [ "$$arch" = "arm64" ]; then echo aarch64-bugleos-linux-musl; \
  else echo; \
  fi)

TARGET ?= $(if $(HOST_TARGET),$(HOST_TARGET),$(error Unsupported host architecture '$(HOST_ARCH)'; please set TARGET explicitly))

TOOLCHAIN_ROOT ?= $(OUT_DIR)/toolchain
TOOLCHAIN ?= $(TOOLCHAIN_ROOT)/$(TARGET)
STAGE1_TOOLCHAIN_ROOT ?= $(OUT_DIR)/toolchain-stage1
STAGE1_TOOLCHAIN ?= $(STAGE1_TOOLCHAIN_ROOT)/$(TARGET)
STAGE1_SYSROOT ?= $(OUT_DIR)/sysroot-stage1/$(TARGET)
SYSROOT ?= $(OUT_DIR)/sysroot/$(TARGET)

JOBS ?= $(shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

TAR ?= tar
WGET ?= wget
SHA256SUM ?= sha256sum
