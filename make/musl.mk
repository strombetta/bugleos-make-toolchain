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
	
	$(call do_step,INSTALL,musl-fix-ldso-symlink, \
		set -e; \
		ldso="$(SYSROOT)/lib/$(MUSL_LDSO)"; \
		if [ -L "$$ldso" ]; then \
		  t="$$(readlink "$$ldso")"; \
		  if [ "$$t" = "/usr/lib/libc.so" ]; then \
		    ln -snf "../usr/lib/libc.so" "$$ldso"; \
		  fi; \
		fi, \
		musl-fix-ldso-symlink)

	$(call do_step,CHECK,musl, \
		test -L "$(SYSROOT)/lib/$(MUSL_LDSO)" && \
		test "$$(readlink "$(SYSROOT)/lib/$(MUSL_LDSO)")" = "../usr/lib/libc.so", \
		musl-check-ldso-relative)

	$(call do_step,CHECK,musl, \
		test -e "$(SYSROOT)/usr/lib/libc.so", \
		musl-check-libc-so-at-usrlib)


	$(call do_step,CHECK,musl, \
		echo "SYSROOT=$(SYSROOT)"; \
		echo "MUSL_LDSO=$(MUSL_LDSO)"; \
		ls -l "$(SYSROOT)/lib/$(MUSL_LDSO)" 2>/dev/null || true; \
		ls -l "$(SYSROOT)/usr/lib/$(MUSL_LDSO)" 2>/dev/null || true; \
		test -f "$(SYSROOT)/lib/$(MUSL_LDSO)" || test -f "$(SYSROOT)/usr/lib/$(MUSL_LDSO)", \
	musl-check-ldso)

	$(Q)touch $@