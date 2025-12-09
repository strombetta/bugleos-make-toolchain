##
# Copyright (c) 2025 Sebastiano Trombetta
# SPDX-License-Identifier: MIT
# Licensed under the MIT License. See LICENSE file for details.
##

include config/paths.mk
include config/versions.mk

ARCHES := x86_64 i686 aarch64

load_target = $(strip $(shell awk -F':=' '/^TARGET/ {gsub(/[ \t]/,"",$$2);print $$2}' config/arch/$(1).mk))
X86_64_TARGET := $(call load_target,x86_64)
I686_TARGET := $(call load_target,i686)
AARCH64_TARGET := $(call load_target,aarch64)

.PHONY: $(ARCHES) toolchain binutils1 gcc1 musl binutils2 gcc2 metadata clean distclean

x86_64:
	@$(MAKE) TARGET=$(X86_64_TARGET) toolchain

i686:
	@$(MAKE) TARGET=$(I686_TARGET) toolchain

aarch64:
	@$(MAKE) TARGET=$(AARCH64_TARGET) toolchain

binutils1:
	@$(MAKE) -f make/binutils1.mk TARGET=$(TARGET) binutils1

gcc1:
	@$(MAKE) -f make/gcc1.mk TARGET=$(TARGET) gcc1

musl:
	@$(MAKE) -f make/musl.mk TARGET=$(TARGET) musl

binutils2:
	@$(MAKE) -f make/binutils2.mk TARGET=$(TARGET) binutils2

gcc2:
	@$(MAKE) -f make/gcc2.mk TARGET=$(TARGET) gcc2

metadata:
	@ROOT_DIR=$(ROOT_DIR) TARGET=$(TARGET) TOOLCHAIN_DIR=$(TOOLCHAIN_DIR) SYSROOT=$(SYSROOT) \
	  $(ROOT_DIR)/scripts/gen-metadata.sh

toolchain: binutils1 gcc1 musl binutils2 gcc2 metadata

clean:
	@rm -rf $(BUILDS_DIR) $(LOGS_DIR)

distclean: clean
	@rm -rf $(OUT_DIR)

