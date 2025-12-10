##
# Copyright (c) 2025 Sebastiano Trombetta
# SPDX-License-Identifier: MIT
# Licensed under the MIT License. See LICENSE file for details.
##

include $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/common.mk)

.PHONY: all
all: gcc2

.PHONY: gcc2
gcc2: ensure-dirs $(GCC_BUILD_DIR)/.built-gcc2

$(GCC2_BUILD_DIR)/.built-gcc2: $(GCC_ARCHIVE)
	@echo "[gcc2] Building final GCC for $(TARGET)"
	@rm -rf $(GCC_BUILD_DIR)
	@mkdir -p $(GCC_BUILD_DIR)
	@$(MAKE) unpack-gcc2
	@cd $(GCC_SRC_DIR) && ./contrib/download_prerequisites > $(LOGS_DIR)/gcc2-prereqs.log 2>&1 || true
	@cd $(GCC_BUILD_DIR) && $(GCC_SRC_DIR)/configure \
	    --target=$(TARGET) \
	    --prefix=$(TOOLCHAIN) \
	    --with-sysroot=$(SYSROOT) \
	    --enable-languages=c,c++ \
	    --disable-nls \
	    --disable-multilib \
	    --enable-checking=release \
	    --disable-libsanitizer \
	    --disable-libitm \
	    --enable-threads=posix \
	    > $(LOGS_DIR)/gcc2-configure.log 2>&1
	@$(MAKE) -C $(GCC_BUILD_DIR) -j$(JOBS) > $(LOGS_DIR)/gcc2-build.log 2>&1
	@$(MAKE) -C $(GCC_BUILD_DIR) install > $(LOGS_DIR)/gcc2-install.log 2>&1
	@touch $@
