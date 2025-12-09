##
# Copyright (c) 2025 Sebastiano Trombetta
# SPDX-License-Identifier: MIT
# Licensed under the MIT License. See LICENSE file for details.
##

THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))
include $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/common.mk)

.PHONY: all
all: binutils2

.PHONY: binutils2
binutils2: ensure-dirs $(BINUTILS2_BUILD_DIR)/.built-stage2

$(BINUTILS2_BUILD_DIR)/.built-stage2: $(BINUTILS_ARCHIVE)
	@echo "[binutils2] Rebuilding binutils against sysroot for $(TARGET)"
	@mkdir -p $(BINUTILS2_BUILD_DIR)
	@$(MAKE) -f $(THIS_MAKEFILE) unpack-binutils
	@cd $(BINUTILS2_BUILD_DIR) && $(BINUTILS_SRC_DIR)/configure \
	--target=$(TARGET) \
	--prefix=$(TOOLCHAIN_DIR) \
	--with-sysroot=$(SYSROOT) \
	--disable-nls \
	--disable-werror \
	--enable-deterministic-archives \
	> $(LOGS_DIR)/binutils2-configure.log 2>&1
	@$(MAKE) -C $(BINUTILS2_BUILD_DIR) -j$(JOBS) > $(LOGS_DIR)/binutils2-build.log 2>&1
	@$(MAKE) -C $(BINUTILS2_BUILD_DIR) install > $(LOGS_DIR)/binutils2-install.log 2>&1
	@touch $@
