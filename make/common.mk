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
include $(ROOT_DIR)/config/paths.mk
include $(ROOT_DIR)/config/versions.mk

# define quite / verbose
ifeq ($(V),1)
	Q :=
else
	Q := @
endif

# $(call do_step, TAG, LABEL, COMMAND, LOGFILE)
define do_step
	$(Q)printf "  %-8s %s\n" "$(1)" "$(2)"
	$(Q){ $(3); } > "$(LOGS_DIR)/$(4).log" 2>&1 || { \
		printf "  %-8s %s [FAILED] (see %s)\n" "$(1)" "$(2)" "$(LOGS_DIR)/$(4).log"; \
	exit 1; }
endef

# Ensure the previously built toolchain binaries are discoverable for subsequent stages.
export PATH := $(TOOLCHAIN)/bin:$(PATH)

HOST ?= $(shell uname -m)-unknown-linux-gnu
PKGDIR ?= $(ROOT_DIR)/patches

FETCH_SOURCES := $(ROOT_DIR)/scripts/fetch-sources.sh

BINUTILS_ARCHIVE := $(DOWNLOADS_DIR)/binutils-$(BINUTILS_VERSION).tar.xz
BINUTILS_SIG := $(DOWNLOADS_DIR)/binutils-$(BINUTILS_VERSION).tar.xz.sig
BINUTILS_SRC_DIR := $(SOURCES_DIR)/binutils-$(BINUTILS_VERSION)
GCC_ARCHIVE := $(DOWNLOADS_DIR)/gcc-$(GCC_VERSION).tar.xz
GCC_SIG := $(DOWNLOADS_DIR)/gcc-$(GCC_VERSION).tar.xz.sig
GCC_SRC_DIR := $(SOURCES_DIR)/gcc-$(GCC_VERSION)
GNU_KEYRING := $(DOWNLOADS_DIR)/gnu-keyring.gpg
MUSL_ARCHIVE := $(DOWNLOADS_DIR)/musl-$(MUSL_VERSION).tar.gz
MUSL_SIG := $(DOWNLOADS_DIR)/musl-$(MUSL_VERSION).tar.gz.asc
MUSL_PUBKEY := $(DOWNLOADS_DIR)/musl.pub
MUSL_SRC_DIR := $(SOURCES_DIR)/musl-$(MUSL_VERSION)

# Directory helpers
BINUTILS1_BUILD_DIR := $(BUILDS_DIR)/binutils-stage1
GCC_BUILD_DIR := $(BUILDS_DIR)/gcc
MUSL_BUILD_DIR := $(BUILDS_DIR)/musl
BINUTILS2_BUILD_DIR := $(BUILDS_DIR)/binutils-stage2

.PHONY: ensure-dirs
ensure-dirs:
	@mkdir -p $(DOWNLOADS_DIR) $(SOURCES_DIR) $(BUILDS_DIR) $(OUT_DIR) $(TOOLCHAIN) $(SYSROOT) $(LOGS_DIR)

.PHONY: fetch-sources
fetch-sources: ensure-dirs
	@$(FETCH_SOURCES)

$(BINUTILS_ARCHIVE) $(BINUTILS_SIG) $(GCC_ARCHIVE) $(GCC_SIG) $(GNU_KEYRING) $(MUSL_ARCHIVE) $(MUSL_SIG) $(MUSL_PUBKEY): | ensure-dirs
	@$(FETCH_SOURCES)

unpack-binutils:
	@rm -rf $(BINUTILS_SRC_DIR)
	@$(TAR) -xf $(BINUTILS_ARCHIVE) -C $(SOURCES_DIR)

unpack-gcc:
	@rm -rf $(GCC_SRC_DIR)
	@$(TAR) -xf $(GCC_ARCHIVE) -C $(SOURCES_DIR)

unpack-musl:
	@rm -rf $(MUSL_SRC_DIR)
	@$(TAR) -xf $(MUSL_ARCHIVE) -C $(SOURCES_DIR)
