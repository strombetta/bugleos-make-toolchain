##
# Copyright (c) 2025 Sebastiano Trombetta
# SPDX-License-Identifier: MIT
# Licensed under the MIT License. See LICENSE file for details.
##

THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))
include $(abspath $(dir $(THIS_MAKEFILE))/common.mk)

.PHONY: all
all: gcc1

.PHONY: gcc1
gcc1: ensure-dirs $(GCC1_BUILD_DIR)/.built-stage1

$(GCC1_BUILD_DIR)/.built-stage1: $(GCC_STAGE1_ARCHIVE)
	@echo "[gcc1] Building bootstrap GCC for $(TARGET)"
	@mkdir -p $(GCC1_BUILD_DIR)
	@$(MAKE) -f $(THIS_MAKEFILE) unpack-gcc1
	@cd $(GCC_STAGE1_SRC_DIR) && ./contrib/download_prerequisites > $(LOGS_DIR)/gcc1-prereqs.log 2>&1 || true
	@cd $(GCC1_BUILD_DIR) && $(GCC_STAGE1_SRC_DIR)/configure \
		--target=$(TARGET) \
		--prefix=$(TOOLCHAIN_DIR) \
		--with-sysroot=$(SYSROOT) \
		--with-newlib \
		--with-native-system-header-dir=/usr/include \
		--without-headers \
		--disable-nls \
		--disable-shared \
		--disable-threads \
		--disable-libmudflap \
		--disable-decimal-float \
		--disable-libatomic \
		--disable-libgomp \
		--disable-libquadmath \
		--disable-libssp \
		--disable-libvtv \
		--disable-multilib \
		--enable-languages=c \
		--enable-checking=release \
		> $(LOGS_DIR)/gcc1-configure.log 2>&1
	@$(MAKE) -C $(GCC1_BUILD_DIR) -j$(JOBS) all-gcc > $(LOGS_DIR)/gcc1-build.log 2>&1
	@$(MAKE) -C $(GCC1_BUILD_DIR) -j$(JOBS) all-target-libgcc > $(LOGS_DIR)/gcc1-libgcc-build.log 2>&1
	@$(MAKE) -C $(GCC1_BUILD_DIR) install-gcc > $(LOGS_DIR)/gcc1-install.log 2>&1
	@$(MAKE) -C $(GCC1_BUILD_DIR) install-target-libgcc > $(LOGS_DIR)/gcc1-libgcc-install.log 2>&1
	@touch $@
