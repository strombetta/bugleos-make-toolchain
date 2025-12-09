##
# Copyright (c) 2025 Sebastiano Trombetta
# SPDX-License-Identifier: MIT
# Licensed under the MIT License. See LICENSE file for details.
##

include $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/common.mk)

.PHONY: all
all: binutils1

.PHONY: binutils1
binutils1: ensure-dirs $(BINUTILS1_BUILD_DIR)/.built-stage1

$(BINUTILS1_BUILD_DIR)/.built-stage1: $(BINUTILS_ARCHIVE)
	@echo "[binutils1] Building stage1 binutils for $(TARGET)"
	@mkdir -p $(BINUTILS1_BUILD_DIR)
	@$(MAKE) unpack-binutils
	@cd $(BINUTILS1_BUILD_DIR) && $(BINUTILS_SRC_DIR)/configure \
	    --target=$(TARGET) \
	    --prefix=$(TOOLCHAIN_DIR) \
	    --with-sysroot=$(SYSROOT) \
	    --disable-nls \
	    --disable-werror \
	    --enable-deterministic-archives \
	    > $(LOGS_DIR)/binutils1-configure.log 2>&1
	@$(MAKE) -C $(BINUTILS1_BUILD_DIR) -j$(JOBS) > $(LOGS_DIR)/binutils1-build.log 2>&1
	@$(MAKE) -C $(BINUTILS1_BUILD_DIR) install > $(LOGS_DIR)/binutils1-install.log 2>&1
	@touch $@
