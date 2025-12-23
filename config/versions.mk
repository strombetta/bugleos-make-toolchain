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

BINUTILS_VERSION := 2.45.1
BINUTILS_URL := https://ftp.gnu.org/gnu/binutils/binutils-$(BINUTILS_VERSION).tar.xz
BINUTILS_SIG_URL := https://ftp.gnu.org/gnu/binutils/binutils-$(BINUTILS_VERSION).tar.xz.sig
BINUTILS_SHA256 := 5fe101e6fe9d18fdec95962d81ed670fdee5f37e3f48f0bef87bddf862513aa5

LINUX_VERSION := 6.18.2
LINUX_URL := https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$(LINUX_VERSION).tar.xz
LINUX_SIG_URL := https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$(LINUX_VERSION).tar.sign
LINUX_KEYRING_URL := https://www.kernel.org/keys.html
LINUX_KEYRING_FPRS := 647F28654894E3BD457199BE38DBBDC86092693E,F41BDF16F35CD80D9E56735BF38153E276D54749,ABAF11C65A2970B130ABE3C479BE3E4300411886,AEE416F7DCCB753BB3D5609D88BCE80F012F54CA
LINUX_SHA256 := 558c6bbab749492b34f99827fe807b0039a744693c21d3a7e03b3a48edaab96a

GCC_VERSION := 15.2.0
GCC_URL := https://ftp.gnu.org/gnu/gcc/gcc-$(GCC_VERSION)/gcc-$(GCC_VERSION).tar.xz
GCC_SIG_URL := https://ftp.gnu.org/gnu/gcc/gcc-$(GCC_VERSION)/gcc-$(GCC_VERSION).tar.xz.sig
GCC_SHA256 := 438fd996826b0c82485a29da03a72d71d6e3541a83ec702df4271f6fe025d24e
GNU_KEYRING_URL := https://ftp.gnu.org/gnu/gnu-keyring.gpg
GNU_KEYRING_FPRS := 1397 5A70 E63C 361C 73AE  69EF 6EEB 81F8 981C 74C7

MUSL_VERSION := 1.2.4
MUSL_URL := https://musl.libc.org/releases/musl-$(MUSL_VERSION).tar.gz
MUSL_SIG_URL := https://musl.libc.org/releases/musl-$(MUSL_VERSION).tar.gz.asc
MUSL_SHA256 := 7a35eae33d5372a7c0da1188de798726f68825513b7ae3ebe97aaaa52114f039
MUSL_PUBKEY_URL := https://musl.libc.org/musl.pub
MUSL_PUBKEY_FPR := 8364 8929 0BB6 B70F 99FF  DA05 56BC DB59 3020 450F
