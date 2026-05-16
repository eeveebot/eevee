---
weight: 501
title: "Custom Resources"
description: "CRDs that define eevee.bot"
draft: false
toc: true
---

Custom Resource Definitions (CRDs) extend the Kubernetes API with eevee-specific resources. They are the language the operator speaks — the shapes of the things it knows how to create, manage, and reconcile.

## API Group

All eevee CRDs belong to the `eevee.bot/v1` API group. Five resource types are defined:

| Kind | Description |
|------|-------------|
| **botmodule** | Defines and manages individual eevee modules (connectors, command handlers, router, etc.). Each botmodule maps to a Kubernetes Deployment with mounted configuration, optional persistent storage, and environment variable injection. |
| **ipcconfig** | Defines inter-process communication infrastructure — a managed NATS deployment with token authentication. Modules reference an ipcconfig to discover their messaging backbone. |
| **s3store** | Declares an S3-compatible object storage connection (endpoint, bucket, credentials). Referenced by backup and restore resources to centralize connection configuration. |
| **backupschedule** | Schedules recurring PVC backups to an S3 store. The operator creates and manages a K8s CronJob for each schedule. |
| **backuprestore** | Triggers a oneshot PVC restore from an S3 store. The operator creates a K8s Job to download and extract the backup. |

For detailed field references and example manifests, see the [v1 API reference](v1/).

## Installation

### Helm

```bash
helm repo add eevee https://helm.eevee.bot
helm repo update
helm install eevee-crds eevee/crds --namespace eevee-bot
```

### npm SDK

```typescript
import { eevee } from '@eeveebot/crds';

// Access CRD objects
eevee.bot.v1.botmodule;
eevee.bot.v1.ipcconfig;
eevee.bot.v1.s3store;
eevee.bot.v1.backupschedule;
eevee.bot.v1.backuprestore;

// Typed interfaces
import type { botmoduleSpec, ipcconfigSpec, s3storeSpec, backupscheduleSpec, backuprestoreSpec } from '@eeveebot/crds';

// cdk8s constructs
import { botmodule, ipcconfig, s3store, backupschedule, backuprestore } from '@eeveebot/crds';
```

Requires an `.npmrc` configured for the `@eeveebot` scope:

```ini
@eeveebot:registry=https://npm.pkg.github.com/
```

## API Reference

- [v1](v1/) — Current stable API version
