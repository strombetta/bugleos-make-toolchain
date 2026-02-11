# BugleOS Cross Toolchain
[![Release](https://github.com/strombetta/bugleos-make-toolchain/actions/workflows/release.yml/badge.svg)](https://github.com/strombetta/bugleos-make-toolchain/actions/workflows/release.yml)

## The Repository
BugleOS Cross Toolchain builds deterministic cross-compilers and system headers for BugleOS across multiple architectures. The repository automates fetching sources, verifying checksums, and orchestrating staged builds of binutils, GCC, and musl.

## Repository layout

- `Makefile`: entry point orchestrating staged builds per architecture.
- `config/`: path definitions and per-architecture target triples.
- `make/`: stage-specific makefiles for binutils, GCC, and musl.
- `scripts/`: helper utilities for fetching sources, verifying checksums, loading the environment, and emitting metadata files.
- `patches/`: placeholder for local patches to upstream sources.
- `downloads/`, `builds/`, `out/`: storage for source archives, build trees, and installed toolchain/sysroot outputs.

## Prerequisites

- Standard POSIX build utilities (bash, tar, make)
- wget or curl for fetching sources
- gpg for signature verification
- A C/C++ build environment (C compiler, g++, binutils)

## Usage

Fetch sources along with signatures and verify both checksums and PGP signatures (recommended before building):

```
scripts/fetch-sources.sh
scripts/verify-checksums.sh
```

Build a toolchain for a specific architecture by overriding `TARGET` on the command line. The umbrella target `toolchain` builds the current `TARGET` from `config/paths.mk` or an override passed on the command line. By default, `TARGET` matches the host architecture when it is supported:

```
make TARGET=aarch64-bugleos-linux-musl toolchain
```

To list optional variables for a specific target, pass the target name via `TARGET`:

```
make help TARGET=toolchain
```

To install Linux UAPI headers into the sysroot, set `WITH_LINUX_HEADERS=1` and update `LINUX_VERSION`/`LINUX_SHA256` in `make/linux-headers.mk`:

```
make WITH_LINUX_HEADERS=1 TARGET=x86_64-bugleos-linux-musl toolchain
```

You can override build parallelism and the toolchain output root:

```
make JOBS=8 TOOLCHAIN_ROOT=/opt/bugleos/toolchain TARGET=x86_64-bugleos-linux-musl toolchain
```

## Using the toolchain environment

After a successful build, load the environment helpers generated in `out/toolchain/<triple>` (where `TOOLCHAIN_ROOT` defaults to `out/toolchain`):

```
source out/toolchain/x86_64-bugleos-linux-musl/bugleos-toolchain.env
```

Bootstrap tools (binutils-stage1 and gcc-stage1) install into `out/toolchain-stage1/<triple>`, keeping temporary artifacts separate from the final cross-toolchain under `out/toolchain/<triple>`. Only the latter is required to build BugleOS userspace or kernels.

Stage1 sysroot contents live under `out/toolchain-stage1/sysroot`, while the final sysroot is located at `out/toolchain/<triple>/sysroot`. Headers are exposed under `out/toolchain/<triple>/sysroot/usr/include` for predictable `--print-sysroot` checks.

Alternatively, enter the environment manually:

```
TARGET=x86_64-bugleos-linux-musl . scripts/enter-env.sh
```

To validate an existing build and ensure the compiler never falls back to host headers, run:

```
make TARGET=aarch64-bugleos-linux-musl verify-toolchain
```

## Validation: make check

Run the toolchain validation target to assert that the installed binaries, sysroot, musl loader/libc, and kernel headers are present and match the requested target triplet and architecture:

```
make TARGET=aarch64-bugleos-linux-musl check
```

## Cleaning / Resetting

The Makefile provides a safe, explicit cleaning interface focused on per-package build artifacts and toolchain outputs. Use `TRIPLET=<triple>` (or `TARGET=<triple>`) to scope to a specific architecture. Destructive targets require `FORCE=1`.

Per-package build cleans (they also remove downstream toolchain stages that depend on the selected package, following the `toolchain` build order):
  - `make clean-binutils` removes binutils build trees, logs, sources, archives/stamps, and installed toolchain outputs.
  - `make clean-gcc` removes GCC build trees, logs, sources, archives/stamps, and installed toolchain outputs.
  - `make clean-musl` removes musl build trees, logs, sources, archives/stamps, and musl-installed sysroot headers/libs (preserving Linux UAPI headers).
  - `make clean-kheaders` removes Linux UAPI header builds, logs, sources, archives/stamps, and the installed Linux headers under the sysroot.

Destructive targets (require `FORCE=1`):

- `make clean-toolchain FORCE=1` removes toolchain outputs (`out/toolchain/<triple>` and `out/toolchain-stage1`).

## Continuous Integration

## Feedback
## Related Projects
## Code of Conduct
## License
Copyright (C) Sebastiano Trombetta. All rights reserved.
This project is licensed under the MIT License. For the full text of the license, see the LICENSE file.
