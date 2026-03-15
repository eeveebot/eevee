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
./docs/scripts/vm.sh version-all [bump-type] [commit-message] [--exclude package]...

# Stage all files for a project or all projects
./docs/scripts/vm.sh stage-all [package] [--exclude package]...

# Push changes for a project or all projects
./docs/scripts/vm.sh git-push [package] [--exclude package]...

# Push tags for a project or all projects
./docs/scripts/vm.sh git-push-tags [package] [--exclude package]...

# Update libraries in all relevant packages
./docs/scripts/vm.sh update-libraries [--exclude package]...

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

# Version all packages except docs and helm
./docs/scripts/vm.sh version-all patch --exclude docs --exclude helm

# Stage all files in all projects
./docs/scripts/vm.sh stage-all

# Stage all files in admin project
./docs/scripts/vm.sh stage-all admin

# Stage all files excluding docs and helm
./docs/scripts/vm.sh stage-all --exclude docs --exclude helm

# Push changes in all projects
./docs/scripts/vm.sh git-push

# Push changes in admin project
./docs/scripts/vm.sh git-push admin

# Push changes excluding docs and helm
./docs/scripts/vm.sh git-push --exclude docs --exclude helm

# Push tags in all projects
./docs/scripts/vm.sh git-push-tags

# Push tags in admin project
./docs/scripts/vm.sh git-push-tags admin

# Push tags excluding docs and helm
./docs/scripts/vm.sh git-push-tags --exclude docs --exclude helm

# Update libraries in all relevant packages
./docs/scripts/vm.sh update-libraries

# Update libraries excluding admin and cli
./docs/scripts/vm.sh update-libraries --exclude admin --exclude cli
```

## Package Dependencies

The version manager automatically updates dependent packages when the `libeevee-js` library is versioned:

- When `libeevee-js` is updated, all dependent packages have their `@eeveebot/libeevee` dependency version updated
- Dependent packages include: admin, connector-irc, connector-discord, echo, router, operator, cli, calculator, dice, emote, weather, help, tell, urltitle, crds, helm

## Backward Compatibility

Existing `tag-and-push.sh` scripts have been removed. Use the master version manager directly instead.

## Library Updates

The `update-libraries` command can be used to update npm dependencies in relevant packages:

```bash
# Update npm dependencies in all relevant packages
./docs/scripts/vm.sh update-libraries

# Update npm dependencies excluding specific packages
./docs/scripts/vm.sh update-libraries --exclude admin --exclude cli
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
   - Create git tags locally (but does not automatically push)
4. To push changes to remote repositories, use the git-push and git-push-tags commands:
   - Push all changes: `./docs/scripts/vm.sh git-push`
   - Push all tags: `./docs/scripts/vm.sh git-push-tags`

## Helm Chart Management

The version manager automatically handles Helm chart updates when relevant packages are versioned:

- When `operator` package is versioned, the operator Helm chart image tag is automatically updated
- When `crds` package is versioned, the CRDs Helm chart image tag is automatically updated
- When any command module (admin, calculator, cli, etc.) is versioned, the bot version in `helm/versions.yaml` is automatically incremented
- When `operator` or `crds` versions change, the corresponding entries in `helm/versions.yaml` are automatically updated

The Helm repository (separate git repository) is automatically tagged when any of these changes occur, but tags must be pushed manually using `./docs/scripts/vm.sh git-push-tags helm`.

## Versioning Strategy

- Library packages (`libeevee-js`) follow semantic versioning
- Application packages follow semantic versioning
- All packages are tagged with their version number (e.g., `1.2.3`)
- Some packages have special tag suffixes:
  - `crds` and `helm` packages are tagged with `-build` suffix (e.g., `1.2.3-build`)
- Helm repository is tagged with version numbers following the pattern `v{package-version}` or `v{bot-version}` for bulk updates
