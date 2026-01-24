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

THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))
include $(abspath $(dir $(THIS_MAKEFILE))/common.mk)

.PHONY: all
all: linux-headers

.PHONY: linux-headers
linux-headers: ensure-dirs $(LINUX_HEADERS_BUILD_DIR)/.built-linux-headers

$(LINUX_HEADERS_BUILD_DIR)/.built-linux-headers: $(LINUX_STAMP)
	$(Q)rm -rf "$(LINUX_HEADERS_BUILD_DIR)"
	$(Q)mkdir -p "$(LINUX_HEADERS_BUILD_DIR)"

	$(call do_step,EXTRACT,linux-headers, \
		$(MAKE) -f "$(THIS_MAKEFILE)" unpack-linux, \
		linux-headers-extract)

	$(call do_step,INSTALL,linux-headers, \
		$(call with_host_env, \
			$(MAKE) -C "$(LINUX_SRC_DIR)" O="$(LINUX_HEADERS_BUILD_DIR)" \
				ARCH="$(LINUX_ARCH)" \
				INSTALL_HDR_PATH="$(SYSROOT)/usr" \
				headers_install \
		), \
		linux-headers-install)

	$(call do_step,CHECK,linux-headers, \
		$(call with_host_env, \
			set -eu; \
			test -f "$(SYSROOT)/usr/include/linux/version.h"; \
			test -f "$(SYSROOT)/usr/include/asm/unistd.h" || test -f "$(SYSROOT)/usr/include/asm-generic/unistd.h"; \
		), \
		linux-headers-check)

	$(Q)touch $@
