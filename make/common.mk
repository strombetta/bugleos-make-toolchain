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

# define comma
COMMA := ","

# define quite / verbose
ifeq ($(V),1)
Q :=
else
Q := @
endif

# $(call do_step, TAG, LABEL, COMMAND, LOGFILE)
define do_step
	$(Q)printf "  %-8s %s\n" "$(1)" "$(2)"
	$(Q){ $(3); } > "$(LOGS_DIR)/$(strip $(4)).log" 2>&1 || { \
	printf "  %-8s %s [FAILED] (see %s)\n" "$(1)" "$(2)" "$(LOGS_DIR)/$(strip $(4)).log"; \
	exit 1; }
endef

# $(call do_download, LABEL, COMMAND, LOGFILE)
define do_download
	$(call do_step,DOWNLOAD,$(1),$(2),$(3))
endef

# $(call do_verify, LABEL, COMMAND, LOGFILE)
define do_verify
	$(call do_step,VERIFY,$(1),$(2),$(3))
endef

# Escape backslashes and double-quotes for safe use inside: sh -c "<cmd>"
define sh_escape
$(subst \,\\,$(subst ",\",$(subst $(newline),; ,$(1))))
endef
newline := '\n'

# $(call with_host_env, COMMAND) Host-only, deterministic PATH
define with_host_env
	env -i HOME="$$HOME" SHELL="/bin/sh" LANG="C" LC_ALL="C" PATH="/usr/bin:/bin" \
		sh -eu -c "$(call sh_escape,$(1))"
endef

# $(call with_cross_env, COMMAND) Cross-enabled, deterministic PATH (host first, then your toolchains)
define with_cross_env
	env -i HOME="$$HOME" SHELL="/bin/sh" LANG="C" LC_ALL="C" \
		PATH="/usr/bin:/bin:$(TOOLCHAIN_ROOT)/bin:$(TOOLCHAIN_ROOT)/$(TARGET)/bin:$(STAGE1_TOOLCHAIN_ROOT)/bin:$(STAGE1_TOOLCHAIN_ROOT)/$(TARGET)/bin" \
		sh -eu -c "$(call sh_escape,$(1))"
endef

# PATH baseline (host tools)
HOST_PATH := /usr/bin:/bin:$(PATH)
# PATH to discover cross tools (prefixed) when needed
CROSS_PATH := $(TOOLCHAIN_ROOT)/bin:$(TOOLCHAIN_ROOT)/$(TARGET)/bin:$(STAGE1_TOOLCHAIN_ROOT)/bin:$(STAGE1_TOOLCHAIN_ROOT)/$(TARGET)/bin

HOST ?= $(shell uname -m)-unknown-linux-gnu
PKGDIR ?= $(ROOT_DIR)/patches

BINUTILS_ARCHIVE := $(DOWNLOADS_DIR)/binutils-$(BINUTILS_VERSION).tar.xz
BINUTILS_SRC_DIR := $(SOURCES_DIR)/binutils-$(BINUTILS_VERSION)
GCC_ARCHIVE := $(DOWNLOADS_DIR)/gcc-$(GCC_VERSION).tar.xz
GCC_SRC_DIR := $(SOURCES_DIR)/gcc-$(GCC_VERSION)
MUSL_ARCHIVE := $(DOWNLOADS_DIR)/musl-$(MUSL_VERSION).tar.gz
MUSL_SRC_DIR := $(SOURCES_DIR)/musl-$(MUSL_VERSION)
BINUTILS_STAMP := $(DOWNLOADS_DIR)/.binutils-$(BINUTILS_VERSION)-verified
GCC_STAMP := $(DOWNLOADS_DIR)/.gcc-$(GCC_VERSION)-verified
MUSL_STAMP := $(DOWNLOADS_DIR)/.musl-$(MUSL_VERSION)-verified

# Directory helpers
BINUTILS1_BUILD_DIR := $(BUILDS_DIR)/binutils-stage1
GCC_BUILD_DIR := $(BUILDS_DIR)/gcc
MUSL_BUILD_DIR := $(BUILDS_DIR)/musl
BINUTILS2_BUILD_DIR := $(BUILDS_DIR)/binutils-stage2

.PHONY: ensure-dirs
ensure-dirs:
	@mkdir -p $(DOWNLOADS_DIR) $(SOURCES_DIR) $(BUILDS_DIR) $(OUT_DIR) $(TOOLCHAIN_ROOT) $(TOOLCHAIN) $(STAGE1_TOOLCHAIN_ROOT) $(SYSROOT) $(STAGE1_SYSROOT) $(LOGS_DIR)

.PHONY: ensure-binutils ensure-gcc ensure-musl
ensure-binutils: $(BINUTILS_STAMP)
ensure-gcc: $(GCC_STAMP)
ensure-musl: $(MUSL_STAMP)

$(BINUTILS_STAMP): | ensure-dirs
	$(call do_download,binutils,$(ROOT_DIR)/scripts/fetch-sources.sh binutils,binutils-download)
	$(call do_verify,binutils,$(ROOT_DIR)/scripts/verify-checksums.sh binutils,binutils-verify)
	$(Q)touch $@

$(GCC_STAMP): | ensure-dirs
	$(call do_download,gcc,$(ROOT_DIR)/scripts/fetch-sources.sh gcc,gcc-download)
	$(call do_verify,gcc,$(ROOT_DIR)/scripts/verify-checksums.sh gcc,gcc-verify)
	$(Q)touch $@

$(MUSL_STAMP): | ensure-dirs
	$(call do_download,musl,$(ROOT_DIR)/scripts/fetch-sources.sh musl,musl-download)
	$(call do_verify,musl,$(ROOT_DIR)/scripts/verify-checksums.sh musl,musl-verify)
	$(Q)touch $@

unpack-binutils: ensure-binutils
	@rm -rf $(BINUTILS_SRC_DIR)
	@$(TAR) -xf $(BINUTILS_ARCHIVE) -C $(SOURCES_DIR)

unpack-gcc: ensure-gcc
	@rm -rf $(GCC_SRC_DIR)
	@$(TAR) -xf $(GCC_ARCHIVE) -C $(SOURCES_DIR)

unpack-musl: ensure-musl
	@rm -rf $(MUSL_SRC_DIR)
	@$(TAR) -xf $(MUSL_ARCHIVE) -C $(SOURCES_DIR)
