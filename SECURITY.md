# Security Policy

This document describes how to report security issues for BugleOS Cross Toolchain.

## Supported Versions

We currently support the latest released version and the `main` branch.

| Version | Supported |
| --- | --- |
| latest | :white_check_mark: |
| older releases | :x: |

## Reporting a Vulnerability

Please report security issues **privately**.

Preferred method:
1. Open a private GitHub Security Advisory:
   https://github.com/strombetta/bugleos-make-toolchain/security/advisories

If you cannot use GitHub Security Advisories, contact the maintainer privately
via the email listed in the maintainer's GitHub profile or commit metadata.

### What to Include

Please include:
- A clear description of the vulnerability and impact
- Steps to reproduce (proof-of-concept if possible)
- Affected versions/commits
- Any suggested fixes or mitigations

## Response Timeline

We aim to:
- Acknowledge receipt within **2 business days**
- Provide a status update within **7 days**
- Coordinate a fix and disclosure schedule as appropriate

Timelines may vary based on complexity and upstream coordination needs.

## Scope

In scope:
- Build scripts, CI workflows, release artifacts, and integrity checks
- Supply-chain or signing/verification issues
- Toolchain configuration that could compromise build outputs

Out of scope:
- Vulnerabilities in upstream projects (binutils/GCC/musl/Linux)
  unless introduced or amplified by this repository

## Coordinated Disclosure

Please do not open public issues or disclose details until a fix or mitigation
is available. We will coordinate disclosure with you.

## Security Updates

Security fixes will be released as new versions. Release notes will reference
the advisory and provide upgrade guidance.
