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

COMMA=","

.PHONY: all
all: gcc-stage2

.PHONY: gcc-stage2
gcc-stage2: ensure-dirs $(GCC_BUILD_DIR)/.built-gcc-stage2

$(GCC_BUILD_DIR)/.built-gcc-stage2: $(GCC_STAMP)
	$(Q)rm -rf $(GCC_BUILD_DIR)
	$(Q)mkdir -p $(GCC_BUILD_DIR)

	$(call do_step,EXTRACT,gcc-stage2, \
		$(MAKE) -f $(THIS_MAKEFILE) unpack-gcc, \
		gcc-stage2-extract)

	$(call do_step,EXTRACT,gcc-stage2-prerequisites, \
		cd $(GCC_SRC_DIR) && ./contrib/download_prerequisites, \
		gcc-stage2-prereqs)

	$(call do_step,CONFIG,gcc-stage2, \
		PATH="$(TOOLCHAIN_ROOT)/bin:$$PATH" && \
      cd $(GCC_BUILD_DIR) && $(GCC_SRC_DIR)/configure \
		--target=$(TARGET) \
		--prefix=$(TOOLCHAIN_ROOT) \
		--with-sysroot=$(SYSROOT) \
		--with-native-system-header-dir=/usr/include \
		--enable-languages=c$(COMMA)c++ \
		--disable-nls \
		--disable-multilib \
		--disable-libsanitizer \
		--disable-libitm \
		--disable-libstdcxx-backtrace \
		--enable-checking=release \
		--enable-threads=posix, \
		gcc-stage2-configure)

	$(call do_step,BUILD,gcc-stage2, \
		PATH="$(TOOLCHAIN_ROOT)/bin:$$PATH" && \
		$(MAKE) -C $(GCC_BUILD_DIR) -j$(JOBS), \
		gcc-stage2-build)
	
	$(call do_step,INSTALL,gcc-stage2, \
		$(MAKE) -C $(GCC_BUILD_DIR) install, \
		gcc-stage2-install)

		$(call do_step,CHECK,gcc-stage2, \
		sh -eu -c '\
			test -x "$(TOOLCHAIN_ROOT)/bin/$(TARGET)-gcc"; \
			test -x "$(TOOLCHAIN_ROOT)/bin/$(TARGET)-g++"; \
			test -x "$(TOOLCHAIN_ROOT)/bin/$(TARGET)-ld"; \
			test -x "$(TOOLCHAIN_ROOT)/bin/$(TARGET)-readelf"; \
			"$(TOOLCHAIN_ROOT)/bin/$(TARGET)-gcc" -dumpmachine | grep -qx "$(TARGET)"; \
			"$(TOOLCHAIN_ROOT)/bin/$(TARGET)-gcc" --print-sysroot | grep -qx "$(SYSROOT)"; \
			\
			printf "%s\n" \
				"#include <stdio.h>" \
				"int main(void){ puts(\"toolchain-ok\"); return 0; }" \
				> /tmp/gcc-stage2-check.c; \
			\
			PATH="$(TOOLCHAIN_ROOT)/bin:$$PATH" \
				"$(TOOLCHAIN_ROOT)/bin/$(TARGET)-gcc" -o /tmp/gcc-stage2-check /tmp/gcc-stage2-check.c; \
			\
			"$(TOOLCHAIN_ROOT)/bin/$(TARGET)-readelf" -l /tmp/gcc-stage2-check | grep -q "$(MUSL_LDSO)"; \
			! "$(TOOLCHAIN_ROOT)/bin/$(TARGET)-readelf" -l /tmp/gcc-stage2-check | grep -q "ld-linux"; \
			rm -f /tmp/gcc-stage2-check.c /tmp/gcc-stage2-check', \
		gcc-stage2-check)
	
	$(Q)touch $@