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
all: gcc-stage2

.PHONY: gcc-stage2
gcc-stage2: $(PROGRESS_DIR)/.gcc-stage2-done

$(PROGRESS_DIR)/.gcc-stage2-done: $(PROGRESS_DIR)/.gcc-stage2-built
	$(Q)touch $@

$(PROGRESS_DIR)/.gcc-stage2-built: $(PROGRESS_DIR)/.gcc-stage2-unpacked
	$(Q)rm -rf "$(GCC_BUILD_DIR)"
	$(Q)mkdir -p "$(GCC_BUILD_DIR)"

	$(call do_step,EXTRACT,gcc-stage2-prerequisites, \
		$(call with_host_env, \
			cd "$(GCC_SRC_DIR)" && ./contrib/download_prerequisites \
		), \
		gcc-stage2-prereqs)

	$(call do_step,CONFIG,gcc-stage2, \
		$(call with_cross_env, \
			cd "$(GCC_BUILD_DIR)" && \
			"$(GCC_SRC_DIR)/configure" \
				--target="$(TARGET)" \
				--prefix="$(TOOLCHAIN_ROOT)" \
				--with-sysroot="$(SYSROOT)" \
				--with-native-system-header-dir=/usr/include \
				--enable-languages=c$(COMMA)c++ \
				--disable-nls \
				--disable-multilib \
				--disable-libsanitizer \
				--disable-libitm \
				--disable-libstdcxx-backtrace \
				--enable-checking=release \
				--enable-threads=posix \
		), \
		gcc-stage2-configure)

	$(call do_step,BUILD,gcc-stage2, \
		$(call with_cross_env, \
			$(MAKE) -C "$(GCC_BUILD_DIR)" -j"$(JOBS)" \
		), \
		gcc-stage2-build)

	$(call do_step,INSTALL,gcc-stage2, \
		$(call with_cross_env, \
			$(MAKE) -C "$(GCC_BUILD_DIR)" install \
		), \
		gcc-stage2-install)

	$(call do_step,CHECK,gcc-stage2, \
		$(call with_host_env, \
			sh -eu -c '\
				cc="$(TOOLCHAIN_ROOT)/bin/$(TARGET)-gcc"; \
				cxx="$(TOOLCHAIN_ROOT)/bin/$(TARGET)-g++"; \
				ld="$(TOOLCHAIN_ROOT)/bin/$(TARGET)-ld"; \
				re="$(TOOLCHAIN_ROOT)/bin/$(TARGET)-readelf"; \
				test -x "$$cc"; \
				test -x "$$cxx"; \
				test -x "$$ld"; \
				test -x "$$re"; \
				"$$cc" -dumpmachine | grep -qx "$(TARGET)"; \
				tool_sysroot="$$( "$$cc" --print-sysroot | sed "s:/*$$::" )"; \
				want_sysroot="$$( printf "%s" "$(SYSROOT)" | sed "s:/*$$::" )"; \
				test "$$tool_sysroot" = "$$want_sysroot"; \
				tmpc="/tmp/gcc-stage2-check.c"; \
				tmpe="/tmp/gcc-stage2-check"; \
				printf "%s\n" \
					"#include <stdio.h>" \
					"int main(void){ puts(\"toolchain-ok\"); return 0; }" \
					> "$$tmpc"; \
				PATH="$(TOOLCHAIN_ROOT)/bin:/usr/bin:/bin" \
					"$$cc" -o "$$tmpe" "$$tmpc"; \
				"$$re" -l "$$tmpe" | grep -q "$(MUSL_LDSO)"; \
				! "$$re" -l "$$tmpe" | grep -q "ld-linux"; \
				rm -f "$$tmpc" "$$tmpe"' \
		), \
		gcc-stage2-check)

	$(Q)touch $@

$(PROGRESS_DIR)/.gcc-stage2-unpacked: $(PROGRESS_DIR)/.gcc-stage2-verified
	$(call do_unpack,gcc, \
		$(call with_host_env, \
			rm -rf "$(GCC_SRC_DIR)"; \
			"$(TAR)" -xf "$(GCC_ARCHIVE)" -C "$(SOURCES_DIR)"), \
		gcc-stage2-unpack)
	$(Q)touch $@

$(PROGRESS_DIR)/.gcc-stage2-verified: $(PROGRESS_DIR)/.gcc-stage2-downloaded
	$(call do_verify,gcc,$(ROOT_DIR)/scripts/verify-checksums.sh gcc,gcc-stage2-verify)
	$(Q)touch $@

$(PROGRESS_DIR)/.gcc-stage2-downloaded: | ensure-dirs
	$(call do_download,gcc,$(ROOT_DIR)/scripts/fetch-sources.sh gcc,gcc-stage2-download)
	$(Q)touch $@
