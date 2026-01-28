# Versioning Policy

BugleOS Cross Toolchain follows Semantic Versioning 2.0.0.

## Version Format

`MAJOR.MINOR.PATCH` stored in the `VERSION` file.

- **MAJOR**: incompatible changes (build outputs, flags, toolchain layout)
- **MINOR**: backward-compatible feature additions
- **PATCH**: backward-compatible bug fixes and reproducibility fixes

## Tags

Release tags follow:

`vMAJOR.MINOR.PATCH`  
or  
`vMAJOR.MINOR.PATCH-PRERELEASE`

Examples:
- `v1.2.3`
- `v1.2.3-rc.1`

## Release Process

1. Update `VERSION` with the next `MAJOR.MINOR.PATCH`.
2. Create an annotated tag using the `Tag from VERSION` workflow.
3. CI builds artifacts, verifies checksums, and publishes the release.

## Pre-releases

Pre-releases are allowed (e.g., `-rc.1`, `-beta.1`) and are published as
pre-release tags in GitHub.

## Hotfixes

Hotfixes increment **PATCH** and follow the same release process.
