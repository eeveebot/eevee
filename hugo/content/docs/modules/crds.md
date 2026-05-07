---
weight: 130
title: "crds"
description: "Custom Resource Definitions for the eevee ecosystem"
draft: false
toc: true
---

The CRDs module provides Custom Resource Definitions (CRDs) that extend the Kubernetes API with eevee-specific resources. It ships as both a Helm chart for direct cluster installation and an npm package (`@eeveebot/crds`) providing a TypeScript SDK and cdk8s constructs.

## Overview

The CRDs module defines two custom resource types in the `eevee.bot/v1` API group:

- **botmodule** — Defines and manages individual eevee modules (connectors, command handlers, router, etc.). Each botmodule maps to a Kubernetes Deployment with mounted configuration, optional persistent storage, and environment variable injection.

- **ipcconfig** — Defines inter-process communication infrastructure, specifically a managed NATS deployment with token authentication. Modules reference an ipcconfig to discover their messaging backbone.

These CRDs are prerequisites for using the eevee Operator to manage eevee deployments.

For detailed field references and example manifests, see:

- [botmodule](../custom-resources/v1/botmodule/) — Full spec and example YAML
- [ipcconfig](../custom-resources/v1/ipcconfig/) — Full spec and example YAML

## Features

- Defines the `botmodule` and `ipcconfig` CRDs for the `eevee.bot/v1` API group
- Helm chart for installing CRDs into a cluster
- TypeScript SDK (`@eeveebot/crds`) with typed interfaces and cdk8s constructs
- Docker image for Job-based CRD installation
- Namespaced CRDs with status subresources

## Installation

### Helm

```bash
helm repo add eevee https://helm.eevee.bot
helm repo update
helm install eevee-crds eevee/crds --namespace eevee-bot
```

### npm SDK

```bash
npm install @eeveebot/crds
```

Requires an `.npmrc` configured for the `@eeveebot` scope:

```ini
@eeveebot:registry=https://npm.pkg.github.com/
```

## Usage

### TypeScript SDK

```typescript
import { eevee } from '@eeveebot/crds';

// Access CRD objects
eevee.bot.v1.botmodule;
eevee.bot.v1.ipcconfig;

// Typed interfaces
import type { botmoduleSpec, ipcconfigSpec } from '@eeveebot/crds';

// cdk8s constructs
import { botmodule, ipcconfig } from '@eeveebot/crds';
```

### Direct Application

The Docker image can run as a Kubernetes Job to apply CRDs:

```bash
docker run --rm ghcr.io/eeveebot/crds:latest
```
