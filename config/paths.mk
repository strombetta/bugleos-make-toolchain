##
# Copyright (c) 2025 Sebastiano Trombetta
# SPDX-License-Identifier: MIT
# Licensed under the MIT License. See LICENSE file for details.
##

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
  elif [ "$$arch" = "i686" ] || [ "$$arch" = "i386" ]; then echo i686-bugleos-linux-musl; \
  elif [ "$$arch" = "aarch64" ] || [ "$$arch" = "arm64" ]; then echo aarch64-bugleos-linux-musl; \
  else echo; \
  fi)

TARGET ?= $(if $(HOST_TARGET),$(HOST_TARGET),$(error Unsupported host architecture '$(HOST_ARCH)'; please set TARGET explicitly))

TOOLCHAIN_DIR ?= $(OUT_DIR)/toolchain/$(TARGET)
SYSROOT ?= $(OUT_DIR)/sysroot/$(TARGET)

JOBS ?= $(shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

TAR ?= tar
WGET ?= wget
SHA256SUM ?= sha256sum
