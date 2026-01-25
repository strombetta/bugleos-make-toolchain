#
# Copyright (c) Sebastiano Trombetta. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

GCC_VERSION := 15.2.0
GCC_URL := https://ftp.gnu.org/gnu/gcc/gcc-$(GCC_VERSION)/gcc-$(GCC_VERSION).tar.xz
GCC_SIG_URL := https://ftp.gnu.org/gnu/gcc/gcc-$(GCC_VERSION)/gcc-$(GCC_VERSION).tar.xz.sig
GCC_SHA256 := 438fd996826b0c82485a29da03a72d71d6e3541a83ec702df4271f6fe025d24e

GNU_KEYRING_URL := https://ftp.gnu.org/gnu/gnu-keyring.gpg
GNU_KEYRING_FPRS := 1397 5A70 E63C 361C 73AE  69EF 6EEB 81F8 981C 74C7

THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))
include $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/helpers.mk)

.PHONY: all
all: gcc-stage1

.PHONY: gcc-stage1
gcc-stage1: $(PROGRESS_DIR)/.gcc-stage1-done

$(PROGRESS_DIR)/.gcc-stage1-done: $(PROGRESS_DIR)/.gcc-stage1-built
	$(Q)touch $@

$(PROGRESS_DIR)/.gcc-stage1-built: $(PROGRESS_DIR)/.gcc-stage1-unpacked
	$(Q)rm -rf $(GCC_BUILD_DIR)
	$(Q)mkdir -p $(GCC_BUILD_DIR)

	$(call do_step,EXTRACT,gcc-stage1-prerequisites, \
		$(call with_host_env,cd "$(GCC_SRC_DIR)" && ./contrib/download_prerequisites), \
		gcc-stage1-prereqs)

	$(call do_step,CONFIG,gcc-stage1, \
		$(call with_host_env,cd "$(GCC_BUILD_DIR)" && \
			"$(GCC_SRC_DIR)/configure" \
				--target="$(TARGET)" \
				--prefix="$(STAGE1_TOOLCHAIN_ROOT)" \
				--with-sysroot="$(STAGE1_SYSROOT)" \
				--with-newlib \
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
				AR_FOR_TARGET="$(STAGE1_TOOLCHAIN_ROOT)/bin/$(TARGET)-ar" \
				AS_FOR_TARGET="$(STAGE1_TOOLCHAIN_ROOT)/bin/$(TARGET)-as" \
				LD_FOR_TARGET="$(STAGE1_TOOLCHAIN_ROOT)/bin/$(TARGET)-ld" \
				NM_FOR_TARGET="$(STAGE1_TOOLCHAIN_ROOT)/bin/$(TARGET)-nm" \
				OBJCOPY_FOR_TARGET="$(STAGE1_TOOLCHAIN_ROOT)/bin/$(TARGET)-objcopy" \
				OBJDUMP_FOR_TARGET="$(STAGE1_TOOLCHAIN_ROOT)/bin/$(TARGET)-objdump" \
				RANLIB_FOR_TARGET="$(STAGE1_TOOLCHAIN_ROOT)/bin/$(TARGET)-ranlib" \
				READELF_FOR_TARGET="$(STAGE1_TOOLCHAIN_ROOT)/bin/$(TARGET)-readelf" \
				STRIP_FOR_TARGET="$(STAGE1_TOOLCHAIN_ROOT)/bin/$(TARGET)-strip"), \
		gcc-stage1-configure)

	$(call do_step,BUILD,gcc-stage1, \
		$(call with_host_env, $(MAKE) -C "$(GCC_BUILD_DIR)" -j"$(JOBS)" all-gcc), \
		gcc-stage1-build)

	$(call do_step,BUILD,gcc-stage1-libgcc, \
		$(call with_host_env, $(MAKE) -C "$(GCC_BUILD_DIR)" -j"$(JOBS)" all-target-libgcc), \
		gcc-stage1-libgcc-build)

	$(call do_step,INSTALL,gcc-stage1, \
		$(call with_host_env, $(MAKE) -C "$(GCC_BUILD_DIR)" install-gcc), \
		gcc-stage1-install)

	$(call do_step,INSTALL,gcc-stage1-libgcc, \
		$(call with_host_env, $(MAKE) -C "$(GCC_BUILD_DIR)" install-target-libgcc), \
		gcc-stage1-libgcc-install)

	$(call do_step,CHECK,gcc-stage1, \
		sh -eu -c '\
			test -x "$(STAGE1_TOOLCHAIN_ROOT)/bin/$(TARGET)-gcc"; \
			test -x "$(STAGE1_TOOLCHAIN_ROOT)/bin/$(TARGET)-ld"; \
			"$(STAGE1_TOOLCHAIN_ROOT)/bin/$(TARGET)-gcc" -dumpmachine | grep -qx "$(TARGET)"; \
			"$(STAGE1_TOOLCHAIN_ROOT)/bin/$(TARGET)-gcc" -v >/dev/null 2>&1; \
			printf "%s\n" "int x;" | \
				PATH="$(STAGE1_TOOLCHAIN_ROOT)/bin:$$PATH" \
				"$(STAGE1_TOOLCHAIN_ROOT)/bin/$(TARGET)-gcc" \
					-x c - -c -o /tmp/gcc-stage1-check.o; \
			rm -f /tmp/gcc-stage1-check.o; \
			"$(STAGE1_TOOLCHAIN_ROOT)/bin/$(TARGET)-ld" -v >/dev/null 2>&1', \
		gcc-stage1-check)

	$(Q)touch $@

$(PROGRESS_DIR)/.gcc-stage1-unpacked: $(PROGRESS_DIR)/.gcc-stage1-verified
	$(call do_unpack,gcc, \
		$(call with_host_env, \
			rm -rf "$(GCC_SRC_DIR)"; \
			"$(TAR)" -xf "$(GCC_ARCHIVE)" -C "$(SOURCES_DIR)"), \
		gcc-stage1-unpack)
	$(Q)touch $@

$(PROGRESS_DIR)/.gcc-stage1-verified: $(PROGRESS_DIR)/.gcc-stage1-downloaded
	$(call do_verify,gcc,$(ROOT_DIR)/scripts/verify-checksums.sh gcc,gcc-stage1-verify)
	$(Q)touch $@

$(PROGRESS_DIR)/.gcc-stage1-downloaded: | ensure-dirs
	$(call do_download,gcc,$(ROOT_DIR)/scripts/fetch-sources.sh gcc,gcc-stage1-download)
	$(Q)touch $@
