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
all: gcc-stage1

.PHONY: gcc-stage1
gcc-stage1: ensure-dirs $(GCC_BUILD_DIR)/.built-stage1

$(GCC_BUILD_DIR)/.built-stage1: $(GCC_STAMP)
	$(Q)rm -rf $(GCC_BUILD_DIR)
	$(Q)mkdir -p $(GCC_BUILD_DIR)

	$(call do_step,EXTRACT,gcc-stage1, \
		$(MAKE) -f $(THIS_MAKEFILE) unpack-gcc, \
		gcc-stage1-extract)

	$(call do_step,EXTRACT,gcc-stage1-prerequisites, \
		cd $(GCC_SRC_DIR) && ./contrib/download_prerequisites, \
		gcc-stage1-prereqs)

	$(call do_step,CONFIG,gcc-stage1, \
		cd $(GCC_BUILD_DIR) && $(GCC_SRC_DIR)/configure \
			--target=$(TARGET) \
			--prefix=$(TOOLCHAIN_ROOT) \
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
			--enable-checking=release, \
			gcc-stage1-configure)

	$(call do_step,BUILD,gcc-stage1, \
		$(MAKE) -C $(GCC_BUILD_DIR) -j$(JOBS) all-gcc, \
		gcc-stage1-build)

	$(call do_step,BUILD,gcc-stage1-libgcc, \
		$(MAKE) -C $(GCC_BUILD_DIR) -j$(JOBS) all-target-libgcc, \
		gcc-stage1-libgcc-build)

	$(call do_step,INSTALL,gcc-stage1, \
		$(MAKE) -C $(GCC_BUILD_DIR) install-gcc, \
		gcc-stage1-install)

	$(call do_step,INSTALL,gcc-stage1-libgcc, \
		$(MAKE) -C $(GCC_BUILD_DIR) install-target-libgcc, \
		gcc-stage1-libgcc-install)
	$(Q)touch $@
