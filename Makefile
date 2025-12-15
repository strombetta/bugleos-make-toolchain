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

ARCHES := aarch64 x86_64
load_target = $(strip $(shell awk -F':=' '/^TARGET/ {gsub(/[ \t]/,"",$$2);print $$2}' config/arch/$(1).mk))

.PHONY: $(ARCHES) toolchain binutils-stage1 gcc-stage1 musl binutils-stage2 gcc-stage2 metadata clean distclean check help sanity

help:
	@echo "BugleOS Cross-toolchain builder"
	@echo
	@echo "Targets:"
	@echo "  make x86_64        Build BugleOS cross-toolchain for x86_64 architecture"
	@echo "  make aarch64       Build BugleOS cross-toolchain for aarch64 architecture"
	@echo "  make clean         Remove builds and logs"
	@echo "  make distclean     Full cleanup"
	@echo "  make check TARGET=<triplet>  Sanity-check an existing toolchain"

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

binutils-stage2:
	@$(MAKE) -f make/binutils-stage2.mk TARGET=$(TARGET) binutils-stage2

gcc-stage2:
	@$(MAKE) -f make/gcc-stage2.mk TARGET=$(TARGET) gcc-stage2

metadata:
	@ROOT_DIR=$(ROOT_DIR) TARGET=$(TARGET) TOOLCHAIN=$(TOOLCHAIN) SYSROOT=$(SYSROOT) \
	  $(ROOT_DIR)/scripts/gen-metadata.sh

toolchain: binutils-stage1 gcc-stage1 musl binutils-stage2 gcc-stage2 metadata

clean:
	@rm -rf $(BUILDS_DIR) $(LOGS_DIR)

distclean: clean
	@rm -rf $(OUT_DIR)

check: guard-TARGET
	@echo "[BugleOS] Checking toolchain for $(TARGET)"
	@command -v $(TARGET)-gcc >/dev/null 2>&1 || { echo "ERROR: $(TARGET)-gcc not found"; exit 1; }
	@echo 'int main(void){return 0;}' > /tmp/bugleos-hello.c
	@$(TARGET)-gcc /tmp/bugleos-hello.c -o /tmp/bugleos-hello || { echo "ERROR: failed to build test program"; exit 1; }
	@echo "[BugleOS] Toolchain for $(TARGET) seems OK"
	@rm -f /tmp/bugleos-hello.c /tmp/bugleos-hello

sanity:
	@true
