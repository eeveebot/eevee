---
weight: 310
title: "Version Management"
description: "so. many. repositories."
draft: false
toc: true
---

This document describes the version management system for the eevee.bot project suite.

## Overview

The eevee.bot project uses a master versioning script to manage versions and git tags across all TypeScript packages in the workspace. The system ensures consistent versioning and handles dependency updates automatically.

## Master Version Manager

The master version manager is located at `./docs/scripts/vm.sh` in the root directory.

### Usage

```bash
# Show current versions of all packages
./docs/scripts/vm.sh status

# Version a specific package
./docs/scripts/vm.sh version <package-name> [bump-type] [commit-message]

# Version all packages
./docs/scripts/vm.sh version-all [bump-type] [commit-message]

# Show help
./docs/scripts/vm.sh help
```

### Bump Types

- `patch` - Increment the patch version (0.0.x) - default
- `minor` - Increment the minor version (0.x.0)
- `major` - Increment the major version (x.0.0)

### Examples

```bash
# Version the admin package with a patch bump
./docs/scripts/vm.sh version admin patch "Fixed admin panel bug"

# Version the libeevee-js library with a minor bump
./docs/scripts/vm.sh version libeevee-js minor "Added new utility functions"

# Version all packages with a patch bump
./docs/scripts/vm.sh version-all patch "Security updates"
```

## Package Dependencies

The version manager automatically updates dependent packages when the `libeevee-js` library is versioned:

- When `libeevee-js` is updated, all dependent packages have their `@eeveebot/libeevee` dependency version updated
- Dependent packages include: admin, connector-irc, echo, router, operator, cli, calculator, dice, emote, weather, help, tell, urltitle, helm, crds

## Backward Compatibility

Existing `tag-and-push.sh` scripts have been removed. Use the master version manager directly instead.

## Library Updates

The `update-libraries.sh` script can be used to update npm dependencies:

```bash
# Update npm dependencies in all packages
./update-libraries.sh

# Version all packages
./update-libraries.sh version-all

# Version just the library package
./update-libraries.sh version-library
```

## Workflow

1. Make your code changes
2. Use the version manager to bump versions:
   - For library changes: `./docs/scripts/vm.sh version libeevee-js [bump-type]`
   - For individual package changes: `./docs/scripts/vm.sh version <package> [bump-type]`
   - For coordinated releases: `./docs/scripts/vm.sh version-all [bump-type]`
3. The script will:
   - Update package.json versions
   - Update dependent package dependencies (when applicable)
   - Commit changes with appropriate messages
   - Create and push git tags

## Helm Chart Management

The version manager automatically handles Helm chart updates when relevant packages are versioned:

- When `operator` package is versioned, the operator Helm chart image tag is automatically updated
- When `crds` package is versioned, the CRDs Helm chart image tag is automatically updated
- When any command module (admin, calculator, cli, etc.) is versioned, the bot version in `helm/versions.yaml` is automatically incremented
- When `operator` or `crds` versions change, the corresponding entries in `helm/versions.yaml` are automatically updated

The Helm repository (separate git repository) is automatically tagged and pushed when any of these changes occur.

## Versioning Strategy

- Library packages (`libeevee-js`) follow semantic versioning
- Application packages follow semantic versioning
- All packages are tagged with their version number (e.g., `1.2.3`)
- Helm repository is tagged with version numbers following the pattern `v{package-version}` or `vhelm-{bump-type}-{timestamp}` for bulk updates