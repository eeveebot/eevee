---
weight: 513
title: "s3store"
description: "eevee.bot/v1/s3store"
draft: false
---

The `s3store` CRD declares an S3-compatible object storage connection. It is referenced by `backupschedule` and `backuprestore` resources to centralize endpoint, bucket, and credential configuration — no need to duplicate connection details across multiple resources.

```yaml
---
apiVersion: eevee.bot/v1
kind: s3store
metadata:
  name: my-minio
  namespace: my-eevee-bot
spec:
  endpoint: https://minio.example.com
  accessId:
    secretKeyRef:
      secret:
        name: minio-creds
      key: accessKeyId
  accessKey:
    secretKeyRef:
      secret:
        name: minio-creds
      key: secretAccessKey
  bucket: eevee-backups
  prefix: prod/
  pathStyle: true
```

## Specification

### Properties

#### `endpoint` (string, required)
S3-compatible endpoint URL (e.g. `https://s3.amazonaws.com` or `https://minio.example.com`)

#### `accessId` (object, required)
Reference to a Kubernetes Secret containing the S3 access key ID.

| Field | Description |
|-------|-------------|
| `secretKeyRef.secret.name` | Name of the Secret |
| `secretKeyRef.secret.namespace` | Namespace of the Secret |
| `secretKeyRef.key` | Key within the Secret containing the access key ID |

#### `accessKey` (object, required)
Reference to a Kubernetes Secret containing the S3 secret access key. Same shape as `accessId`.

| Field | Description |
|-------|-------------|
| `secretKeyRef.secret.name` | Name of the Secret |
| `secretKeyRef.secret.namespace` | Namespace of the Secret |
| `secretKeyRef.key` | Key within the Secret containing the secret access key |

#### `bucket` (string, required)
S3 bucket name

#### `prefix` (string, optional)
Common file prefix within the bucket for all objects managed by this store (e.g. `eevee/backups/`)

#### `pathStyle` (boolean, optional)
Use path-style addressing (`host/bucket`) instead of virtual-hosted-style (`bucket.host`). Set to `true` for MinIO and similar stores. Default: `false`

## Status

| Field | Description |
|-------|-------------|
| `conditions` | Standard condition objects with `lastTransitionTime`, `message`, `reason` |
| `lastConnectionTest` | Timestamp of the last successful connection test to the S3 endpoint |
