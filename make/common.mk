# Common definitions for BugleOS toolchain builds
##
# Copyright (c) 2025 Sebastiano Trombetta
# SPDX-License-Identifier: MIT
# Licensed under the MIT License. See LICENSE file for details.
##

ROOT_DIR ?= $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
include $(ROOT_DIR)/config/paths.mk
include $(ROOT_DIR)/config/versions.mk

# Ensure the previously built toolchain binaries are discoverable for subsequent stages.
export PATH := $(TOOLCHAIN)/bin:$(PATH)

HOST ?= $(shell uname -m)-unknown-linux-gnu
PKGDIR ?= $(ROOT_DIR)/patches

BINUTILS_ARCHIVE := $(DOWNLOADS_DIR)/binutils-$(BINUTILS_VERSION).tar.xz
BINUTILS_SRC_DIR := $(SOURCES_DIR)/binutils-$(BINUTILS_VERSION)
GCC_ARCHIVE := $(DOWNLOADS_DIR)/gcc-$(GCC_VERSION).tar.xz
GCC_SRC_DIR := $(SOURCES_DIR)/gcc-$(GCC_VERSION)
MUSL_ARCHIVE := $(DOWNLOADS_DIR)/musl-$(MUSL_VERSION).tar.gz
MUSL_SRC_DIR := $(SOURCES_DIR)/musl-$(MUSL_VERSION)

# Directory helpers
BINUTILS1_BUILD_DIR := $(BUILDS_DIR)/binutils-stage1
GCC_BUILD_DIR := $(BUILDS_DIR)/gcc
MUSL_BUILD_DIR := $(BUILDS_DIR)/musl
BINUTILS2_BUILD_DIR := $(BUILDS_DIR)/binutils-stage2

# Tools
MAKEFLAGS += --no-builtin-rules

.PHONY: ensure-dirs
ensure-dirs:
	@mkdir -p $(DOWNLOADS_DIR) $(SOURCES_DIR) $(BUILDS_DIR) $(OUT_DIR) $(TOOLCHAIN) $(SYSROOT) $(LOGS_DIR)

unpack-binutils:
	@rm -rf $(BINUTILS_SRC_DIR)
	@$(TAR) -xf $(BINUTILS_ARCHIVE) -C $(SOURCES_DIR)

unpack-gcc:
	@rm -rf $(GCC_SRC_DIR)
	@$(TAR) -xf $(GCC_ARCHIVE) -C $(SOURCES_DIR)

unpack-musl:
	@rm -rf $(MUSL_SRC_DIR)
	@$(TAR) -xf $(MUSL_ARCHIVE) -C $(SOURCES_DIR)
