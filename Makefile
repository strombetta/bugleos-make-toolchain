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

include config/paths.mk
include config/versions.mk

MAKEFLAGS += --no-print-directory
WITH_LINUX_HEADERS ?= 0

ARCHES := aarch64 x86_64
load_target = $(strip $(shell awk -F':=' '/^TARGET/ {gsub(/[ \t]/,"",$$2);print $$2}' config/arch/$(1).mk))

.PHONY: $(ARCHES) toolchain binutils-stage1 gcc-stage1 musl linux-headers binutils-stage2 gcc-stage2 metadata verify-toolchain clean distclean check help sanity

help:
	@echo "BugleOS Cross-toolchain builder"
	@echo
	@echo "Targets:"
	@echo "  make x86_64        Build BugleOS cross-toolchain for x86_64 architecture"
	@echo "  make aarch64       Build BugleOS cross-toolchain for aarch64 architecture"
	@echo "  make clean         Remove builds and logs"
	@echo "  make distclean     Full cleanup"
	@echo "  make check TARGET=<triplet>  Sanity-check an existing toolchain"
	@echo "  make WITH_LINUX_HEADERS=1 <arch>  Build toolchain with Linux UAPI headers"
	@echo "  make linux-headers Build Linux UAPI headers into the sysroot"

$(ARCHES):
	@$(MAKE) TARGET=$(call load_target,$@) toolchain

guard-%:
	@test -n "$($*)" || { echo "ERROR: $* is not set"; exit 1; }

binutils-stage1:
	@$(MAKE) -f make/binutils-stage1.mk TARGET=$(TARGET) binutils-stage1

gcc-stage1:
	@$(MAKE) -f make/gcc-stage1.mk TARGET=$(TARGET) gcc-stage1

musl:
	@$(MAKE) -f make/musl.mk TARGET=$(TARGET) musl

linux-headers:
	@$(MAKE) -f make/linux-headers.mk TARGET=$(TARGET) linux-headers

binutils-stage2:
	@$(MAKE) -f make/binutils-stage2.mk TARGET=$(TARGET) binutils-stage2

gcc-stage2:
	@$(MAKE) -f make/gcc-stage2.mk TARGET=$(TARGET) gcc-stage2

verify-toolchain: guard-TARGET
	@ROOT_DIR=$(ROOT_DIR) TARGET=$(TARGET) TOOLCHAIN_ROOT=$(TOOLCHAIN_ROOT) TOOLCHAIN=$(TOOLCHAIN_TARGET_DIR) SYSROOT=$(SYSROOT) \
		PATH="$(TOOLCHAIN_ROOT)/bin:$(TOOLCHAIN_TARGET_DIR)/bin:$$PATH" \
		$(ROOT_DIR)/scripts/verify-toolchain.sh

toolchain: binutils-stage1 linux-headers gcc-stage1 musl binutils-stage2 gcc-stage2

clean:
	@rm -rf $(BUILDS_DIR) $(LOGS_DIR)

distclean: clean
	@rm -rf $(OUT_DIR)

check: verify-toolchain

sanity:
	@true