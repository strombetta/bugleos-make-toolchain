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

TARGET ?= x86_64-bugleos-linux-musl

TOOLCHAIN_DIR ?= $(OUT_DIR)/toolchain/$(TARGET)
SYSROOT ?= $(OUT_DIR)/sysroot/$(TARGET)

JOBS ?= $(shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

TAR ?= tar
WGET ?= wget
SHA256SUM ?= sha256sum
