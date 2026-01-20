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

include config/paths.mk
include config/versions.mk
include make/common.mk

ROOT_DIR := $(abspath $(ROOT_DIR))

include Makefile.help

MAKEFLAGS += --no-print-directory

ARCHES := aarch64 x86_64
load_target = $(strip $(shell awk -F':=' '/^TARGET/ {gsub(/[ \t]/,"",$$2);print $$2}' config/arch/$(1).mk))

TRIPLET ?= $(TARGET)

REPO_ROOT := $(abspath $(CURDIR))

define safe_remove
	@target="$(1)"; \
	abs="$(abspath $(1))"; \
	repo="$(REPO_ROOT)"; \
	if [ -z "$$target" ] || [ -z "$$abs" ] || [ "$$abs" = "/" ]; then \
		echo "ERROR: Refusing to remove unsafe path '$$abs'."; \
		exit 1; \
	fi; \
	if [ "$$abs" = "$$repo" ]; then \
		echo "ERROR: Refusing to remove repository root '$$abs'."; \
		exit 1; \
	fi; \
	case "$$abs" in "$$repo"|"$$repo"/*) ;; \
	*) echo "ERROR: Refusing to remove $$abs (outside $$repo)."; exit 1;; \
	esac; \
	echo "  removing $$abs"; \
	rm -rf -- "$$abs"
endef

define safe_remove_glob
	@dir="$(1)"; \
	pattern="$(2)"; \
	abs="$(abspath $(1))"; \
	repo="$(REPO_ROOT)"; \
	if [ -z "$$dir" ] || [ -z "$$abs" ] || [ "$$abs" = "/" ]; then \
		echo "ERROR: Refusing to remove unsafe path '$$abs'."; \
		exit 1; \
	fi; \
	if [ "$$abs" = "$$repo" ]; then \
		echo "ERROR: Refusing to remove repository root '$$abs'."; \
		exit 1; \
	fi; \
	case "$$abs" in "$$repo"|"$$repo"/*) ;; \
	*) echo "ERROR: Refusing to remove $$abs (outside $$repo)."; exit 1;; \
	esac; \
	echo "  removing $$abs/$$pattern"; \
	rm -rf -- "$$abs"/$$pattern
endef

BINUTILS_TOOLS := addr2line ar as c++filt elfedit gprof ld ld.bfd ld.gold nm objcopy objdump ranlib readelf size strings strip
GCC_TOOLS := gcc g++ cpp gcc-ar gcc-nm gcc-ranlib gcov gcov-dump gcov-tool
MUSL_LIBS := libc libm libpthread librt libdl libutil libxnet libresolv libcrypt

.PHONY: $(ARCHES) toolchain binutils-stage1 linux-headers gcc-stage1 musl binutils-stage2 gcc-stage2 verify-toolchain \
	clean-toolchain clean-binutils clean-gcc clean-musl clean-kheaders \
	clean-binutils-stage2 clean-gcc-stage2 \
	check sanity

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

clean-toolchain: clean-binutils clean-gcc clean-musl clean-kheaders clean-binutils-stage2 clean-gcc-stage2 ## Remove toolchain output for the current triplet (plus logs/output cleanup)
	@echo "==> Removing toolchain outputs for $(TRIPLET)"
	$(call safe_remove,$(LOGS_DIR))
	$(call safe_remove,$(OUT_DIR))
	$(call safe_remove,$(TOOLCHAIN_TARGET_DIR))
	$(call safe_remove,$(STAGE1_TOOLCHAIN_ROOT))

clean-binutils: clean-gcc ## Remove binutils build directories
	@echo "==> Cleaning binutils build outputs"
	$(call safe_remove,$(BINUTILS1_BUILD_DIR))
	$(call safe_remove,$(BINUTILS2_BUILD_DIR))
	$(call safe_remove,$(BINUTILS_SRC_DIR))
	$(call safe_remove,$(BINUTILS_STAMP))
	$(call safe_remove,$(BINUTILS_ARCHIVE))
	$(call safe_remove_glob,$(LOGS_DIR),binutils-stage1-*.log)
	$(call safe_remove_glob,$(LOGS_DIR),binutils-stage2-*.log)
	$(foreach tool,$(BINUTILS_TOOLS),$(call safe_remove,$(STAGE1_TOOLCHAIN_ROOT)/bin/$(TARGET)-$(tool)))
	$(foreach tool,$(BINUTILS_TOOLS),$(call safe_remove,$(TOOLCHAIN_ROOT)/bin/$(TARGET)-$(tool)))
	$(call safe_remove_glob,$(STAGE1_TOOLCHAIN_ROOT)/lib,libbfd.*)
	$(call safe_remove_glob,$(STAGE1_TOOLCHAIN_ROOT)/lib,libopcodes.*)
	$(call safe_remove_glob,$(STAGE1_TOOLCHAIN_ROOT)/lib,libiberty.*)
	$(call safe_remove_glob,$(STAGE1_TOOLCHAIN_ROOT)/lib,libctf.*)
	$(call safe_remove_glob,$(STAGE1_TOOLCHAIN_ROOT)/lib,libctf-nobfd.*)
	$(call safe_remove_glob,$(STAGE1_TOOLCHAIN_ROOT)/lib,libgprofng.*)
	$(call safe_remove_glob,$(TOOLCHAIN_ROOT)/lib,libbfd.*)
	$(call safe_remove_glob,$(TOOLCHAIN_ROOT)/lib,libopcodes.*)
	$(call safe_remove_glob,$(TOOLCHAIN_ROOT)/lib,libiberty.*)
	$(call safe_remove_glob,$(TOOLCHAIN_ROOT)/lib,libctf.*)
	$(call safe_remove_glob,$(TOOLCHAIN_ROOT)/lib,libctf-nobfd.*)
	$(call safe_remove_glob,$(TOOLCHAIN_ROOT)/lib,libgprofng.*)

clean-binutils-stage2:
	@echo "==> Cleaning binutils stage2 outputs"
	$(call safe_remove,$(BINUTILS2_BUILD_DIR))
	$(call safe_remove_glob,$(LOGS_DIR),binutils-stage2-*.log)
	$(foreach tool,$(BINUTILS_TOOLS),$(call safe_remove,$(TOOLCHAIN_ROOT)/bin/$(TARGET)-$(tool)))
	$(call safe_remove_glob,$(TOOLCHAIN_ROOT)/lib,libbfd.*)
	$(call safe_remove_glob,$(TOOLCHAIN_ROOT)/lib,libopcodes.*)
	$(call safe_remove_glob,$(TOOLCHAIN_ROOT)/lib,libiberty.*)
	$(call safe_remove_glob,$(TOOLCHAIN_ROOT)/lib,libctf.*)
	$(call safe_remove_glob,$(TOOLCHAIN_ROOT)/lib,libctf-nobfd.*)
	$(call safe_remove_glob,$(TOOLCHAIN_ROOT)/lib,libgprofng.*)

clean-gcc: clean-musl ## Remove GCC build directory
	@echo "==> Cleaning GCC build outputs"
	$(call safe_remove,$(GCC_BUILD_DIR))
	$(call safe_remove,$(GCC_SRC_DIR))
	$(call safe_remove,$(GCC_STAMP))
	$(call safe_remove,$(GCC_ARCHIVE))
	$(call safe_remove_glob,$(LOGS_DIR),gcc-stage1-*.log)
	$(call safe_remove_glob,$(LOGS_DIR),gcc-stage2-*.log)
	$(foreach tool,$(GCC_TOOLS),$(call safe_remove,$(STAGE1_TOOLCHAIN_ROOT)/bin/$(TARGET)-$(tool)))
	$(foreach tool,$(GCC_TOOLS),$(call safe_remove,$(TOOLCHAIN_ROOT)/bin/$(TARGET)-$(tool)))
	$(call safe_remove,$(STAGE1_TOOLCHAIN_ROOT)/lib/gcc/$(TARGET))
	$(call safe_remove,$(TOOLCHAIN_ROOT)/lib/gcc/$(TARGET))
	$(call safe_remove,$(STAGE1_TOOLCHAIN_ROOT)/libexec/gcc/$(TARGET))
	$(call safe_remove,$(TOOLCHAIN_ROOT)/libexec/gcc/$(TARGET))
	$(call safe_remove,$(STAGE1_TOOLCHAIN_ROOT)/$(TARGET)/lib)
	$(call safe_remove,$(STAGE1_TOOLCHAIN_ROOT)/$(TARGET)/lib64)
	$(call safe_remove,$(STAGE1_TOOLCHAIN_ROOT)/$(TARGET)/include)
	$(call safe_remove,$(TOOLCHAIN_ROOT)/$(TARGET)/lib)
	$(call safe_remove,$(TOOLCHAIN_ROOT)/$(TARGET)/lib64)
	$(call safe_remove,$(TOOLCHAIN_ROOT)/$(TARGET)/include)

clean-gcc-stage2:
	@echo "==> Cleaning GCC stage2 outputs"
	$(call safe_remove_glob,$(LOGS_DIR),gcc-stage2-*.log)
	$(foreach tool,$(GCC_TOOLS),$(call safe_remove,$(TOOLCHAIN_ROOT)/bin/$(TARGET)-$(tool)))
	$(call safe_remove,$(TOOLCHAIN_ROOT)/lib/gcc/$(TARGET))
	$(call safe_remove,$(TOOLCHAIN_ROOT)/libexec/gcc/$(TARGET))
	$(call safe_remove,$(TOOLCHAIN_ROOT)/$(TARGET)/lib)
	$(call safe_remove,$(TOOLCHAIN_ROOT)/$(TARGET)/lib64)
	$(call safe_remove,$(TOOLCHAIN_ROOT)/$(TARGET)/include)

clean-musl: clean-binutils-stage2 clean-gcc-stage2 ## Remove musl build directory
	@echo "==> Cleaning musl build outputs"
	$(call safe_remove,$(MUSL_BUILD_DIR))
	$(call safe_remove,$(MUSL_SRC_DIR))
	$(call safe_remove,$(MUSL_STAMP))
	$(call safe_remove,$(MUSL_ARCHIVE))
	$(call safe_remove_glob,$(LOGS_DIR),musl-*.log)
	$(foreach lib,$(MUSL_LIBS),$(call safe_remove_glob,$(SYSROOT)/lib,$(lib).*))
	$(foreach lib,$(MUSL_LIBS),$(call safe_remove_glob,$(SYSROOT)/usr/lib,$(lib).*))
	$(call safe_remove,$(SYSROOT)/lib/$(MUSL_LDSO))
	$(call safe_remove,$(SYSROOT)/usr/lib/$(MUSL_LDSO))
	$(call safe_remove,$(SYSROOT)/lib/crt1.o)
	$(call safe_remove,$(SYSROOT)/lib/crti.o)
	$(call safe_remove,$(SYSROOT)/lib/crtn.o)
	$(call safe_remove,$(SYSROOT)/usr/lib/crt1.o)
	$(call safe_remove,$(SYSROOT)/usr/lib/crti.o)
	$(call safe_remove,$(SYSROOT)/usr/lib/crtn.o)
	@include_dir="$(SYSROOT)/usr/include"; \
	abs="$(abspath $(SYSROOT)/usr/include)"; \
	repo="$(REPO_ROOT)"; \
	if [ -z "$$include_dir" ] || [ -z "$$abs" ] || [ "$$abs" = "/" ] || [ "$$abs" = "$$repo" ]; then \
		echo "ERROR: Refusing to remove unsafe path '$$abs'."; \
		exit 1; \
	fi; \
	case "$$abs" in "$$repo"|"$$repo"/*) ;; \
	*) echo "ERROR: Refusing to remove $$abs (outside $$repo)."; exit 1;; \
	esac; \
	if [ -d "$$abs" ]; then \
		echo "  removing musl headers under $$abs (preserving linux/asm/asm-generic)"; \
		find "$$abs" -mindepth 1 -maxdepth 1 \
			! -name linux ! -name asm ! -name asm-generic \
			-exec rm -rf -- {} +; \
	fi

clean-kheaders: clean-gcc ## Remove Linux UAPI headers build directory
	@echo "==> Cleaning Linux headers build outputs"
	$(call safe_remove,$(LINUX_HEADERS_BUILD_DIR))
	$(call safe_remove,$(LINUX_SRC_DIR))
	$(call safe_remove,$(LINUX_STAMP))
	$(call safe_remove,$(LINUX_ARCHIVE))
	$(call safe_remove_glob,$(LOGS_DIR),linux-headers-*.log)
	$(call safe_remove,$(SYSROOT)/usr/include/linux)
	$(call safe_remove,$(SYSROOT)/usr/include/asm)
	$(call safe_remove,$(SYSROOT)/usr/include/asm-generic)

check: verify-toolchain

sanity:
	@true
