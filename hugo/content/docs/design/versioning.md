---
weight: 310
title: "Version Management"
description: "so. many. repositories."
draft: false
toc: true
---

This document describes the version management system for the eevee.bot project suite.

## Overview

Each eevee module manages its own version independently via its `package.json`. Modules with shared dependencies (e.g., `@eeveebot/libeevee`) can use the `npm run update-libraries` script available in each package to bump shared dependency versions.

> **Note:** A master versioning script (`vm.sh`) was previously used to coordinate version bumps across all packages but has been removed. The versioning workflow below describes the manual process for versioning individual packages.

## Versioning Workflow

1. Make your code changes
2. Update the version in the module's `package.json`
3. Commit with an appropriate message
4. Tag the commit with the version number
5. Push changes and tags to the remote repository

### Updating Dependencies

Each package with `@eeveebot/libeevee` as a dependency has an `npm run update-libraries` script that updates core eevee libraries to their latest versions.

## Package Dependencies

When `libeevee-js` is updated, dependent packages should have their `@eeveebot/libeevee` dependency version updated. Dependent packages include: admin, connector-irc, connector-discord, echo, router, operator, cli, calculator, dice, emote, weather, help, tell, urltitle, crds, helm.

## Helm Chart Management

The version manager automatically handles Helm chart updates when relevant packages are versioned:

- When `operator` package is versioned, the operator Helm chart image tag is automatically updated
- When `crds` package is versioned, the CRDs Helm chart image tag is automatically updated
- When any command module (admin, calculator, cli, etc.) is versioned, the bot version in `helm/versions.yaml` is automatically incremented
- When `operator` or `crds` versions change, the corresponding entries in `helm/versions.yaml` are automatically updated

The Helm repository (separate git repository) is automatically tagged when any of these changes occur. Tags must be pushed manually to the remote.

## Versioning Strategy

- Library packages (`libeevee-js`) follow semantic versioning
- Application packages follow semantic versioning
- All packages are tagged with their version number (e.g., `1.2.3`)
- Some packages have special tag suffixes:
  - `crds` and `helm` packages are tagged with `-build` suffix (e.g., `1.2.3-build`)
- Helm repository is tagged with version numbers following the pattern `v{package-version}` or `v{bot-version}` for bulk updates
