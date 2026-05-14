---
weight: 513
title: "s3store"
description: "eevee.bot/v1/s3store"
draft: false
---

The `s3store` CRD declares an S3-compatible object storage connection. It is referenced by `BackupSchedule` and `BackupRestore` resources to centralize endpoint, bucket, and credential configuration — no need to duplicate connection details across multiple resources.

```yaml
---
apiVersion: eevee.bot/v1
kind: S3Store
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
  # region: eu-west-1
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

#### `region` (string, optional)
S3 region. For AWS, this should match the bucket region (e.g. `eu-west-1`). For S3-compatible stores (MinIO, Garage, etc.) the region may not matter — the default `us-east-1` is used when omitted.

#### `signatureV2` (boolean, optional)
Use S3 v2 signature instead of v4. Set to `true` for Ceph RADOSGW and older S3-compatible stores that require v2 signatures. Modern stores (AWS S3, MinIO, Garage) support v4 — leave `false`. Default: `false`

#### `pathStyle` (boolean, optional)
Use path-style addressing (`host/bucket`) instead of virtual-hosted-style (`bucket.host`). Set to `true` for MinIO and similar stores. Default: `false`

## Status

| Field | Description |
|-------|-------------|
| `conditions` | Standard Kubernetes condition objects (`type`, `status`, `reason`, `message`, `lastTransitionTime`). The `Ready` condition reflects whether the S3 connection test succeeded. |
