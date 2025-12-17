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

THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))
include $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/common.mk)

.PHONY: all
all: binutils-stage1

.PHONY: binutils-stage1
binutils-stage1: ensure-dirs $(BINUTILS1_BUILD_DIR)/.built-stage1

$(BINUTILS1_BUILD_DIR)/.built-stage1: $(BINUTILS_STAMP)
	$(Q)rm -rf $(BINUTILS1_BUILD_DIR)
	$(Q)mkdir -p $(BINUTILS1_BUILD_DIR)

	$(call do_step,EXTRACT,binutils-stage1, \
		$(MAKE) -f $(THIS_MAKEFILE) unpack-binutils, \
		binutils-stage1-extract)

	$(call do_step,CONFIG,binutils-stage1, \
	cd $(BINUTILS1_BUILD_DIR) && $(BINUTILS_SRC_DIR)/configure \
	--target=$(TARGET) \
	--prefix=$(STAGE1_TOOLCHAIN_ROOT) \
	--with-sysroot=$(STAGE1_SYSROOT) \
	--disable-nls \
	--disable-werror \
	--enable-deterministic-archives, \
	binutils-stage1-configure)

	$(call do_step,BUILD,binutils-stage1, \
		$(MAKE) -C "$(BINUTILS1_BUILD_DIR)" -j"$(JOBS)", \
		binutils-stage1-build)

	$(call do_step,INSTALL,binutils-stage1, \
		$(MAKE) -C "$(BINUTILS1_BUILD_DIR)" install, \
		binutils-stage1-install)

	$(Q)touch $@
