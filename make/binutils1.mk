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
include $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/common.mk)

.PHONY: all
all: binutils1

.PHONY: binutils1
binutils1: ensure-dirs $(BINUTILS1_BUILD_DIR)/.built-stage1

$(BINUTILS1_BUILD_DIR)/.built-stage1: $(BINUTILS_ARCHIVE)
	@echo "[BugleOS] Building GNU Binutils v$(BINUTILS_VERSION) for $(TARGET)"
	@mkdir -p $(BINUTILS1_BUILD_DIR)
	@$(MAKE) -f $(THIS_MAKEFILE) unpack-binutils
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
