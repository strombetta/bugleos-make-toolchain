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
include $(abspath $(dir $(THIS_MAKEFILE))/common.mk)

.PHONY: all
all: musl

.PHONY: musl
musl: ensure-dirs $(MUSL_BUILD_DIR)/.built-musl

$(MUSL_BUILD_DIR)/.built-musl: $(MUSL_STAMP)
	$(Q)rm -rf $(MUSL_BUILD_DIR)
	$(Q)mkdir -p $(MUSL_BUILD_DIR)
	echo "LDSO = $(MUSL_LDSO)"

	$(call do_step,EXTRACT,musl, \
		$(MAKE) -f $(THIS_MAKEFILE) unpack-musl, \
		musl-extract)

	$(call do_step,CONFIG,musl, \
		PATH="$(STAGE1_TOOLCHAIN_ROOT)/bin:$$PATH" && \
		cd "$(MUSL_BUILD_DIR)" && "$(MUSL_SRC_DIR)/configure" \
			CC="$(STAGE1_TOOLCHAIN_ROOT)/bin/$(TARGET)-gcc" \
			--prefix=/usr \
			--target="$(TARGET)" \
			--host="$(TARGET)" \
			--enable-wrapper=no \
			--syslibdir=/lib, \
		musl-configure)

	$(call do_step,INSTALL,musl-headers, \
		PATH="$(STAGE1_TOOLCHAIN_ROOT)/bin:$$PATH" && \
		$(MAKE) -C "$(MUSL_BUILD_DIR)" DESTDIR="$(SYSROOT)" install-headers, \
		musl-headers)

	$(call do_step,BUILD,musl, \
		PATH="$(STAGE1_TOOLCHAIN_ROOT)/bin:$$PATH" && \
		$(MAKE) -C "$(MUSL_BUILD_DIR)" -j"$(JOBS)" CROSS_COMPILE="$(TARGET)-", \
		musl-build)

	$(call do_step,INSTALL,musl, \
		PATH="$(STAGE1_TOOLCHAIN_ROOT)/bin:$$PATH" && \
		$(MAKE) -C "$(MUSL_BUILD_DIR)" DESTDIR="$(SYSROOT)" install, \
		musl-install)

		$(call do_step,CHECK,musl, \
		test -f "$(SYSROOT)/usr/include/stdio.h", \
		musl-check-stdio-h)

	$(call do_step,CHECK,musl, \
		test -f "$(SYSROOT)/usr/include/stdlib.h", \
		musl-check-stdlib-h)

	$(call do_step,CHECK,musl, \
		test -f "$(SYSROOT)/usr/include/unistd.h", \
		musl-check-unistd-h)

	$(call do_step,CHECK,musl, \
		test -f "$(SYSROOT)/usr/include/errno.h", \
		musl-check-errno-h)

	$(call do_step,CHECK,musl, \
		test -f "$(SYSROOT)/usr/include/pthread.h", \
		musl-check-pthread-h)

	$(call do_step,CHECK,musl, \
		test -f "$(SYSROOT)/lib/$(MUSL_LDSO)" || test -f "$(SYSROOT)/usr/lib/$(MUSL_LDSO)", \
		musl-check-ldso)

	$(call do_step,CHECK,musl, \
		test -f "$(SYSROOT)/lib/crt1.o" || test -f "$(SYSROOT)/usr/lib/crt1.o", \
		musl-check-crt1-o)

	$(call do_step,CHECK,musl, \
		test -f "$(SYSROOT)/lib/crti.o" || test -f "$(SYSROOT)/usr/lib/crti.o", \
		musl-check-crti-o)

	$(call do_step,CHECK,musl, \
		test -f "$(SYSROOT)/lib/crtn.o" || test -f "$(SYSROOT)/usr/lib/crtn.o", \
		musl-check-crtn-o)

	$(call do_step,CHECK,musl, \
		ls -1 "$(SYSROOT)/lib/libc.so"* >/dev/null 2>&1 || ls -1 "$(SYSROOT)/usr/lib/libc.so"* >/dev/null 2>&1, \
		musl-check-libc-so)

	$(Q)touch $@