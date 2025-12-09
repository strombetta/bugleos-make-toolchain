##
# Copyright (c) 2025 Sebastiano Trombetta
# SPDX-License-Identifier: MIT
# Licensed under the MIT License. See LICENSE file for details.
##

include $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/common.mk)

.PHONY: all
all: musl

.PHONY: musl
musl: ensure-dirs $(MUSL_BUILD_DIR)/.built-musl

$(MUSL_BUILD_DIR)/.built-musl: $(MUSL_ARCHIVE)
	@echo "[musl] Building musl libc for $(TARGET)"
	@mkdir -p $(MUSL_BUILD_DIR)
	@$(MAKE) unpack-musl
	@cd $(MUSL_SRC_DIR) && CC="$(TARGET)-gcc" ./configure \
	    --prefix=/usr \
	    --target=$(TARGET) \
	    --host=$(TARGET) \
	    --enable-wrapper=no \
	    --syslibdir=/lib \
	    > $(LOGS_DIR)/musl-configure.log 2>&1
	@$(MAKE) -C $(MUSL_SRC_DIR) DESTDIR=$(SYSROOT) install-headers > $(LOGS_DIR)/musl-headers.log 2>&1
	@$(MAKE) -C $(MUSL_SRC_DIR) -j$(JOBS) CROSS_COMPILE=$(TARGET)- > $(LOGS_DIR)/musl-build.log 2>&1
	@$(MAKE) -C $(MUSL_SRC_DIR) DESTDIR=$(SYSROOT) install > $(LOGS_DIR)/musl-install.log 2>&1
	@touch $@
