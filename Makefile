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

ARCHES := x86_64 i686 aarch64

load_target = $(strip $(shell awk -F':=' '/^TARGET/ {gsub(/[ \t]/,"",$$2);print $$2}' config/arch/$(1).mk))
X86_64_TARGET := $(call load_target,x86_64)
I686_TARGET := $(call load_target,i686)
AARCH64_TARGET := $(call load_target,aarch64)

.PHONY: $(ARCHES) toolchain binutils1 gcc1 musl binutils2 gcc2 metadata clean distclean check

x86_64:
	@$(MAKE) TARGET=$(X86_64_TARGET) toolchain

i686:
	@$(MAKE) TARGET=$(I686_TARGET) toolchain

aarch64:
	@$(MAKE) TARGET=$(AARCH64_TARGET) toolchain

binutils1:
	@$(MAKE) -f make/binutils1.mk TARGET=$(TARGET) binutils1

gcc1:
	@$(MAKE) -f make/gcc1.mk TARGET=$(TARGET) gcc1

musl:
	@$(MAKE) -f make/musl.mk TARGET=$(TARGET) musl

binutils2:
	@$(MAKE) -f make/binutils2.mk TARGET=$(TARGET) binutils2

gcc2:
	@$(MAKE) -f make/gcc2.mk TARGET=$(TARGET) gcc2

metadata:
	@ROOT_DIR=$(ROOT_DIR) TARGET=$(TARGET) TOOLCHAIN=$(TOOLCHAIN) SYSROOT=$(SYSROOT) \
	  $(ROOT_DIR)/scripts/gen-metadata.sh

toolchain: binutils1 gcc1 musl binutils2 gcc2 metadata

check:
	@echo "PATH = $(PATH)"
	@which $(TARGET)-nm || echo "ERROR: $(TARGET)-nm non trovato"
	@which $(TARGET)-ld || echo "ERROR: $(TARGET)-ld non trovato"
	@echo "NM_FOR_TARGET = $(NM_FOR_TARGET)"
	@echo "LD_FOR_TARGET = $(LD_FOR_TARGET)"

clean:
	@rm -rf $(BUILDS_DIR) $(LOGS_DIR)

distclean: clean
	@rm -rf $(OUT_DIR)

