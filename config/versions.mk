##
# Copyright (c) 2025 Sebastiano Trombetta
# SPDX-License-Identifier: MIT
# Licensed under the MIT License. See LICENSE file for details.
##

BINUTILS_VERSION := 2.45.1
BINUTILS_URL := https://ftp.gnu.org/gnu/binutils/binutils-$(BINUTILS_VERSION).tar.xz
BINUTILS_SIG_URL := https://ftp.gnu.org/gnu/binutils/binutils-$(BINUTILS_VERSION).tar.xz.sig
BINUTILS_SHA256 := SHA256_PLACEHOLDER_BINUTILS

GCC_STAGE1_VERSION := 15.2.0
GCC_STAGE1_URL := https://ftp.gnu.org/gnu/gcc/gcc-$(GCC_STAGE1_VERSION)/gcc-$(GCC_STAGE1_VERSION).tar.xz
GCC_STAGE1_SIG_URL := https://ftp.gnu.org/gnu/gcc/gcc-$(GCC_STAGE1_VERSION)/gcc-$(GCC_STAGE1_VERSION).tar.xz.sig
GCC_STAGE1_SHA256 := SHA256_PLACEHOLDER_GCC_STAGE1

GCC_VERSION := 15.2.0
GCC_URL := https://ftp.gnu.org/gnu/gcc/gcc-$(GCC_VERSION)/gcc-$(GCC_VERSION).tar.xz
GCC_SIG_URL := https://ftp.gnu.org/gnu/gcc/gcc-$(GCC_VERSION)/gcc-$(GCC_VERSION).tar.xz.sig
GCC_SHA256 := SHA256_PLACEHOLDER_GCC

MUSL_VERSION := 1.2.4
MUSL_URL := https://musl.libc.org/releases/musl-$(MUSL_VERSION).tar.gz
MUSL_SIG_URL := https://musl.libc.org/releases/musl-$(MUSL_VERSION).tar.gz.asc
MUSL_SHA256 := SHA256_PLACEHOLDER_MUSL

GNU_KEYRING_URL := https://ftp.gnu.org/gnu/gnu-keyring.gpg
MUSL_PUBKEY_URL := https://musl.libc.org/musl.pub
