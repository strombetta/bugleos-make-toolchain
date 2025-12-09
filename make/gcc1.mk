##
# Copyright (c) 2025 Sebastiano Trombetta
# SPDX-License-Identifier: MIT
# Licensed under the MIT License. See LICENSE file for details.
##

include $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/common.mk)

.PHONY: all
all: gcc1

.PHONY: gcc1
gcc1: ensure-dirs $(GCC1_BUILD_DIR)/.built-stage1

$(GCC1_BUILD_DIR)/.built-stage1: $(GCC_STAGE1_ARCHIVE)
	@echo "[gcc1] Building bootstrap GCC for $(TARGET)"
	@mkdir -p $(GCC1_BUILD_DIR)
	@$(MAKE) unpack-gcc1
	@cd $(GCC_STAGE1_SRC_DIR) && ./contrib/download_prerequisites > $(LOGS_DIR)/gcc1-prereqs.log 2>&1 || true
	@cd $(GCC1_BUILD_DIR) && $(GCC_STAGE1_SRC_DIR)/configure \
	    --target=$(TARGET) \
	    --prefix=$(TOOLCHAIN_DIR) \
	    --with-sysroot=$(SYSROOT) \
	    --enable-languages=c \
	    --without-headers \
	    --disable-nls \
	    --disable-shared \
	    --disable-threads \
	    --disable-libatomic \
	    --disable-libgomp \
	    --disable-libmudflap \
	    --disable-libssp \
	    --disable-multilib \
	    --disable-decimal-float \
	    --disable-libquadmath \
	    --with-newlib \
	    --enable-checking=release \
	    > $(LOGS_DIR)/gcc1-configure.log 2>&1
	@$(MAKE) -C $(GCC1_BUILD_DIR) -j$(JOBS) all-gcc > $(LOGS_DIR)/gcc1-build.log 2>&1
	@$(MAKE) -C $(GCC1_BUILD_DIR) install-gcc > $(LOGS_DIR)/gcc1-install.log 2>&1
	@touch $@
