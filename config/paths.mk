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
  case "$(HOST_ARCH)" in \
    x86_64|amd64)		echo x86_64-bugleos-linux-musl ;; \
    i686|i386)			echo i686-bugleos-linux-musl ;; \
    aarch64|arm64)	echo aarch64-bugleos-linux-musl ;; \
    *) 							echo ;; \
	esac)

TARGET ?= $(if $(HOST_TARGET),$(HOST_TARGET),$(error Unsupported host architecture '$(HOST_ARCH)'; please set TARGET explicitly))

TOOLCHAIN_DIR ?= $(OUT_DIR)/toolchain/$(TARGET)
SYSROOT ?= $(OUT_DIR)/sysroot/$(TARGET)

JOBS ?= $(shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

TAR ?= tar
WGET ?= wget
SHA256SUM ?= sha256sum
