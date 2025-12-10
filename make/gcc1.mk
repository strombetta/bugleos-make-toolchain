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

THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))
include $(abspath $(dir $(THIS_MAKEFILE))/common.mk)

TOOLCHAIN_BIN := $(TOOLCHAIN_DIR)/bin
PATH := $(TOOLCHAIN_BIN):$(PATH)
export PATH
export NM_FOR_TARGET			:= $(TARGET)-nm
export AR_FOR_TARGET			:= $(TARGET)-ar
export AS_FOR_TARGET			:= $(TARGET)-as
export LD_FOR_TARGET			:= $(TARGET)-ld
export RANLIB_FOR_TARGET	:= $(TARGET)-ranlib
export OBJDUMP_FOR_TARGET	:= $(TARGET)-objdump
export OBJCOPY_FOR_TARGET	:= $(TARGET)-objcopy

.PHONY: all
all: gcc1

.PHONY: gcc1
gcc1: ensure-dirs $(GCC1_BUILD_DIR)/.built-stage1

$(GCC1_BUILD_DIR)/.built-stage1: $(GCC_STAGE1_ARCHIVE)
	@echo "[BugleOS] Building GNU GCC v$(GCC_VERSION) for $(TARGET)"
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

	check-toolchain:
		@echo "PATH = $(PATH)"
		@which $(TARGET)-nm || echo "ERROR: $(TARGET)-nm non trovato"
		@which $(TARGET)-ld || echo "ERROR: $(TARGET)-ld non trovato"
		@echo "NM_FOR_TARGET = $(NM_FOR_TARGET)"
		@echo "LD_FOR_TARGET = $(LD_FOR_TARGET)"
