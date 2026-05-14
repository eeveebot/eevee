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
kind: BackupRestore
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
Reference to the `BotModule` whose PVC will be restored.

| Field | Description |
|-------|-------------|
| `name` | Name of the BotModule resource in the same namespace |

#### `s3Store` (object, required)
Reference to the `S3Store` CR instance containing the backup.

| Field | Description |
|-------|-------------|
| `name` | Name of the S3Store resource in the same namespace |

#### `image` (string, required)
Container image to use for the restore job (e.g. `ghcr.io/eevee/backup:latest`)

#### `backupId` (string, optional)
UUID of the specific backup to restore. If omitted, the operator lists objects at the module's S3 prefix and restores the latest backup by S3 `LastModified` timestamp.

#### `cleanRestore` (boolean, optional)
If `true`, the restore script will delete all existing data in the PVC before extracting the backup archive, ensuring no leftover files from a previous state. Default: `false`

## Status

| Field | Description |
|-------|-------------|
| `conditions` | Standard Kubernetes condition objects (`type`, `status`, `reason`, `message`, `lastTransitionTime`). The `Ready` condition reflects whether the restore job completed successfully. |

## Retrying a Failed Restore

Once a `backuprestore` reaches a terminal state (`Ready=True` or `Ready=False`), the operator will not re-process it. To retry a failed restore, delete the CR and create a new one — you can reuse the same name:

```bash
kubectl delete backuprestore mybot-restore-latest -n my-eevee-bot
kubectl apply -f mybot-restore-latest.yaml
```

## Bootstrap from Backup

For automatic restoration on first deployment, use `BotModule.spec.bootstrapFromBackup` instead of creating a `BackupRestore` CR manually. See the [botmodule](../botmodule/) docs for details.
