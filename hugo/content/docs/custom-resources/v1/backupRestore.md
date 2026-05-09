---
weight: 515
title: "backuprestore"
description: "eevee.bot/v1/backuprestore"
draft: false
---

The `backuprestore` CRD triggers a oneshot PVC restore from an S3 store. The eevee operator creates a Kubernetes Job to download and extract the specified backup. If no specific backup ID is provided, the operator restores the latest backup for the target module.

```yaml
---
apiVersion: eevee.bot/v1
kind: backuprestore
metadata:
  name: mybot-restore-latest
  namespace: my-eevee-bot
spec:
  botModule:
    name: mybot
  s3Store:
    name: my-minio
  image: ghcr.io/eevee/backup:latest
  # backupId: "a1b2c3d4-e5f6-7890-abcd-ef1234567890"  # omit for latest
```

## Specification

### Properties

#### `botModule` (object, required)
Reference to the `botmodule` whose PVC will be restored.

| Field | Description |
|-------|-------------|
| `name` | Name of the botmodule resource in the same namespace |

#### `s3Store` (object, required)
Reference to the `s3store` CR instance containing the backup.

| Field | Description |
|-------|-------------|
| `name` | Name of the s3store resource in the same namespace |

#### `image` (string, required)
Container image to use for the restore job (e.g. `ghcr.io/eevee/backup:latest`)

#### `backupId` (string, optional)
UUID of the specific backup to restore. If omitted, the operator lists objects at the module's S3 prefix and restores the latest backup by S3 `LastModified` timestamp.

## Status

| Field | Description |
|-------|-------------|
| `conditions` | Standard condition objects with `lastTransitionTime`, `message`, `reason` |
| `jobName` | Name of the managed K8s Job |
| `restoredBackupId` | UUID of the backup that was restored |
| `phase` | Phase of the restore operation (`Pending`, `Running`, `Succeeded`, `Failed`) |

## Bootstrap from Backup

For automatic restoration on first deployment, use `botmodule.spec.bootstrapFromBackup` instead of creating a `backuprestore` CR manually. See the [botmodule](../botmodule/) docs for details.
