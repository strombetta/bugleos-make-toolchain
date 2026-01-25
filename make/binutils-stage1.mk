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

BINUTILS_VERSION := 2.45.1
BINUTILS_URL := https://ftp.gnu.org/gnu/binutils/binutils-$(BINUTILS_VERSION).tar.xz
BINUTILS_SIG_URL := https://ftp.gnu.org/gnu/binutils/binutils-$(BINUTILS_VERSION).tar.xz.sig
BINUTILS_SHA256 := 5fe101e6fe9d18fdec95962d81ed670fdee5f37e3f48f0bef87bddf862513aa5

GNU_KEYRING_URL := https://ftp.gnu.org/gnu/gnu-keyring.gpg
GNU_KEYRING_FPRS := 1397 5A70 E63C 361C 73AE  69EF 6EEB 81F8 981C 74C7

THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))
include $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/helpers.mk)

.PHONY: all
all: binutils-stage1

.PHONY: binutils-stage1
binutils-stage1: $(PROGRESS_DIR)/.binutils-stage1-done

$(PROGRESS_DIR)/.binutils-stage1-done: $(PROGRESS_DIR)/.binutils-stage1-built
	$(Q)touch $@

$(PROGRESS_DIR)/.binutils-stage1-built: $(PROGRESS_DIR)/.binutils-stage1-unpacked
	$(Q)rm -rf $(BINUTILS1_BUILD_DIR)
	$(Q)mkdir -p $(BINUTILS1_BUILD_DIR)

	$(call do_step,CONFIG,binutils-stage1, \
		$(call with_host_env, cd "$(BINUTILS1_BUILD_DIR)" && "$(BINUTILS_SRC_DIR)/configure" \
			--target="$(TARGET)" \
			--prefix="$(STAGE1_TOOLCHAIN_ROOT)" \
			--with-sysroot="$(STAGE1_SYSROOT)" \
			--disable-nls \
			--disable-werror \
			--enable-deterministic-archives), \
		binutils-stage1-configure)

	$(call do_step,BUILD,binutils-stage1, \
		$(call with_host_env, $(MAKE) -C "$(BINUTILS1_BUILD_DIR)" -j"$(JOBS)"), \
		binutils-stage1-build)

	$(call do_step,INSTALL,binutils-stage1, \
		$(call with_host_env, $(MAKE) -C "$(BINUTILS1_BUILD_DIR)" install), \
		binutils-stage1-install)

	$(call do_step,CHECK,binutils-stage1, \
		sh -eu -c '\
			test -x "$(STAGE1_TOOLCHAIN_ROOT)/bin/$(TARGET)-ld"; \
			test -x "$(STAGE1_TOOLCHAIN_ROOT)/bin/$(TARGET)-as"; \
			test -x "$(STAGE1_TOOLCHAIN_ROOT)/bin/$(TARGET)-ar"; \
			"$(STAGE1_TOOLCHAIN_ROOT)/bin/$(TARGET)-ld" -v >/dev/null 2>&1', \
		binutils-stage1-check)

	$(Q)touch $@

$(PROGRESS_DIR)/.binutils-stage1-unpacked: $(PROGRESS_DIR)/.binutils-stage1-verified
	$(call do_unpack,binutils, \
		$(call with_host_env, \
			rm -rf "$(BINUTILS_SRC_DIR)"; \
			"$(TAR)" -xf "$(BINUTILS_ARCHIVE)" -C "$(SOURCES_DIR)"), \
		binutils-stage1-unpack)
	$(Q)touch $@

$(PROGRESS_DIR)/.binutils-stage1-verified: $(PROGRESS_DIR)/.binutils-stage1-downloaded
	$(call do_verify,binutils,$(ROOT_DIR)/scripts/verify-checksums.sh binutils,binutils-stage1-verify)
	$(Q)touch $@

$(PROGRESS_DIR)/.binutils-stage1-downloaded: | ensure-dirs
	$(call do_download,binutils,$(ROOT_DIR)/scripts/fetch-sources.sh binutils,binutils-stage1-download)
	$(Q)touch $@
