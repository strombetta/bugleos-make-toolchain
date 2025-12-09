# Copyright (c) 2025 Sebastiano Trombetta
# SPDX-License-Identifier: MIT
# Licensed under the MIT License. See LICENSE file for details.

# BugleOS Toolchain

BugleOS Toolchain builds deterministic cross-compilers and system headers for BugleOS across multiple architectures. The repository automates fetching sources, verifying checksums, and orchestrating staged builds of binutils, GCC, and musl.

## Repository layout

- `Makefile`: entry point orchestrating staged builds per architecture.
- `config/`: central version and path definitions, plus per-architecture target triples.
- `make/`: stage-specific makefiles for binutils, GCC, and musl.
- `scripts/`: helper utilities for fetching sources, verifying checksums, loading the environment, and emitting metadata files.
- `patches/`: placeholder for local patches to upstream sources.
- `downloads/`, `builds/`, `out/`: storage for source archives, build trees, and installed toolchain/sysroot outputs.

## Prerequisites

- Standard POSIX build utilities (bash, tar, make)
- wget or curl for fetching sources
- A C/C++ build environment (C compiler, g++, binutils)

## Usage

Fetch sources and verify checksums (optional):

```
scripts/fetch-sources.sh
scripts/verify-checksums.sh
```

Build a toolchain for a specific architecture:

```
make x86_64
make i686
make aarch64
```

The umbrella target `toolchain` builds the current `TARGET` from `config/paths.mk` or an override passed on the command line:

```
make TARGET=aarch64-bugleos-linux-musl toolchain
```

## Using the toolchain environment

After a successful build, load the environment helpers generated in `out/toolchain/<triple>`:

```
source out/toolchain/x86_64-bugleos-linux-musl/bugleos-toolchain.env
```

Alternatively, enter the environment manually:

```
TARGET=x86_64-bugleos-linux-musl scripts/enter-env.sh
```

## Cleaning

- `make clean` removes `builds/` and `logs/` only.
- `make distclean` additionally removes `out/` while preserving downloads.

## Continuous Integration

GitHub Actions runs shell linting and basic Makefile sanity checks on every push and pull request. The workflow lives in `.github/workflows/ci.yml` and ensures scripts remain syntactically correct while metadata generation stays functional.
