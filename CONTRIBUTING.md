# Contributing to BugleOS Cross Toolchain

Thank you for your interest in contributing to **bugleos-make-toolchain**.  
This document provides a high-level overview of how you can participate and support the evolution of the BugleOS toolchain build system.

Unlike general-purpose applications, this project focuses on deterministic, reproducible builds of a cross-toolchain (Binutils, GCC, Musl) via GNU Make. Contributions may involve code, documentation, feedback, or testing.

## Asking Questions

If you have a question about how the build system works, how to extend it, or how to troubleshoot build problems, please do **not** open an issue immediately.

Use the project's preferred community channels (to be defined for BugleOS).  
A clear and well-structured question will help other developers facing similar challenges.

## Providing Feedback

Feedback on architecture, documentation clarity, build performance, or developer experience is welcome.

For structured discussions, use the repository’s “Discussions” area (if available) or reference specific Makefile sections when opening an issue.

## Reporting Issues

If you have identified a reproducible bug or a well-defined feature request, please report it following the guidelines below.

### Identify Where to Report

BugleOS is composed of multiple repositories. Ensure that the issue is filed in the correct one. Examples:

- Toolchain logic → **bugleos-make-toolchain**
- Root filesystem build → `bugleos-rootfs`
- BusyBox or runtime behavior → respective repository

### Look For an Existing Issue

Before opening a new issue:

1. Search through open issues.  
2. Check recently closed issues.  
3. Avoid creating duplicates.

If an issue already exists, add relevant comments or use GitHub reactions instead of posting “+1”.

### Writing Effective Bug Reports and Feature Requests

Please file **one issue per distinct problem or feature**.  
Do not combine multiple unrelated topics.

To help maintainers reproduce the problem, include:

* Version of bugleos-make-toolchain (commit hash)
* Host operating system and version
* Versions of Make, GCC, and Binutils installed on the host
* Target architecture (e.g., `x86_64-linux-musl`, `aarch64-linux-musl`)
* Reproducible steps (1, 2, 3…)
* Expected vs. actual behavior
* Logs from the `logs/` directory
* Output of:
  * `$(TARGET)-gcc --version`
  * `file toolchain/bin/<compiler>`
* Minimal code snippet (if the issue relates to compiled output)

Avoid supplying code only as images. Maintainers need text they can copy and paste.

## Creating Pull Requests

Please follow the project’s PR guidelines:

- Submit **one logical change per PR**
- Ensure the PR builds successfully
- Document relevant changes in `CHANGELOG.md`
- Do not commit generated files (artifacts, logs, build outputs)

A high-quality PR typically includes:

- A clear description of the change
- Motivation and reasoning
- Testing evidence
- Any impact on reproducibility

## Final Checklist Before Submitting an Issue or PR

* [ ] Verify that no existing issue covers your topic  
* [ ] Ensure the problem is reproducible from a clean state (`make clean`)  
* [ ] Minimize and isolate the problem  
* [ ] Include complete logs when appropriate  

Do not be discouraged if maintainers request more information.  
Toolchain and build-system issues often require precise, low-level diagnostics.

## Automated Issue Management

BugleOS may use GitHub Actions or similar tooling for automatic issue triage. Examples:

- Automatically closing issues missing required information
- Automatically locking long-closed issues
- Supporting a structured feature-request pipeline

If an automation behaves incorrectly, open a new issue and report it.

## Contributing Fixes

If you want to implement fixes or improvements in the build system, ensure that you:

- Understand the toolchain build stages (binutils stage1 → gcc stage1 → musl → binutils stage2 → gcc stage2)
- Preserve determinism and reproducibility
- Validate builds for at least one target architecture

For significant refactoring, refer to internal project guidelines or open a discussion first.

## Thank You

Your contributions—large or small—help improve BugleOS and its toolchain.  
Thank you for taking the time to support this project.
