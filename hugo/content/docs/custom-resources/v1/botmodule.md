---
weight: 512
title: "botmodule"
description: "eevee.bot/v1/botmodule"
draft: false
---

This file defines a Custom Resource for bot modules in the eevee.bot/v1 API. It shows how to configure a bot module with settings such as:

- Number of instances to run
- Container image to use
- Image pull policy
- Metrics configuration
- IPC configuration reference
- Module name
- Persistent volume configuration
- Volume mount path
- Arbitrary module configuration
- Enable/disable toggle
- Secret injection for environment variables
- Operator API token mounting

The botmodule CRD allows you to define and deploy individual bot modules that communicate through the eevee.bot messaging system.

```yaml
---
apiVersion: eevee.bot/v1
kind: BotModule
metadata:
  name: my-module
  namespace: my-eevee-bot
spec:
  enabled: true
  size: 1
  image: ghcr.io/eeveebot/module:latest
  pullPolicy: Always
  metrics: false
  metricsPort: 9000
  ipcConfig: my-eevee-bot
  moduleName: my-module
  persistentVolumeClaim:
    accessModes:
    - ReadWriteOnce
    resources:
      requests:
        storage: 1Gi
  volumeMountPath: /data
  mountOperatorApiToken: false
  envSecret:
    name: my-module-secrets
  moduleConfig: |
    # Arbitrary configuration passed to the module
    setting1: value1
    setting2: value2
```

## Specification

### Properties

#### `size` (integer)
Size defines the number of botmodule instances
Default: 1

#### `image` (string)
Image defines the container image to use
Default: "ghcr.io/eeveebot/module:latest"

#### `pullPolicy` (string)
PullPolicy defines the image pull policy to use
Default: "Always"

#### `metrics` (boolean)
Metrics defines whether to enable metrics or not
Default: false

#### `metricsPort` (integer)
MetricsPort defines the port to expose metrics on
Default: 9000

#### `ipcConfig` (string)
IPC configuration name

#### `moduleName` (string)
ModuleName defines the name of the module

#### `persistentVolumeClaim` (object)
PersistentVolumeClaim defines the PVC configuration for the module

#### `volumeMountPath` (string)
VolumeMountPath defines where to mount the PVC in the container
Default: "/data"

#### `moduleConfig` (string)
ModuleConfig is a passthrough field for arbitrary YAML configuration that will be passed directly to the module as a multi-line string

#### `mountOperatorApiToken` (boolean)
MountOperatorApiToken defines whether to mount the operator API token
Default: false

#### `enabled` (boolean)
Enabled defines whether the botmodule is enabled or disabled
Default: true

#### `envSecret` (object)
EnvSecret defines optional secrets to be injected as environment variables

#### `livenessProbe` (object, optional)
LivenessProbe defines a custom liveness probe for the module pod. Accepts a standard Kubernetes `V1Probe` object (httpGet, tcpSocket, exec, etc.). If not specified, the operator provides a default HTTP GET probe against `/health` on the module's metricsPort.

#### `readinessProbe` (object, optional)
ReadinessProbe defines a custom readiness probe for the module pod. Accepts a standard Kubernetes `V1Probe` object. If not specified, the operator provides a default HTTP GET probe against `/health` on the module's metricsPort.

#### `startupProbe` (object, optional)
StartupProbe defines a custom startup probe for the module pod. Accepts a standard Kubernetes `V1Probe` object. If not specified, no startup probe is set (modules typically start quickly).

#### `backupSchedule` (object, optional)
Reference to a `BackupSchedule` resource in the same namespace. When set, the operator wires up backup CronJobs targeting this module's PVC.

| Field | Description |
|-------|-------------|
| `name` | Name of the BackupSchedule resource |

#### `bootstrapFromBackup` (object, optional)
When set, the operator restores the latest backup from S3 into this module's PVC before starting the deployment for the first time. Subsequent reconciliations ignore this field (no re-restore). The operator tracks bootstrapped state via the `eevee.bot/bootstrapped` annotation on the PVC itself.

| Field | Description |
|-------|-------------|
| `s3Store.name` | Name of the S3Store resource containing the backup |
| `image` | Container image to use for the restore job |

### Status

The operator updates the `status` subresource on every reconciliation to reflect the current state of the module.

| Field | Description |
|-------|-------------|
| `conditions` | Standard Kubernetes condition objects (`type`, `status`, `reason`, `message`, `lastTransitionTime`). The `Ready` condition reflects whether the deployment is healthy. The `Bootstrapped` condition tracks `bootstrapFromBackup` progress. |

#### Condition reasons

| Reason | Condition | Description |
|--------|-----------|-------------|
| `Pending` | Ready | Reconciliation in progress |
| `WaitingForBackup` | Bootstrapped | `bootstrapFromBackup` is set but no backups were found in S3 |
| `Bootstrapping` | Bootstrapped | A restore Job is running to bootstrap the PVC from a backup |
| `BootstrapRestoreFailed` | Bootstrapped | The bootstrap restore Job failed or timed out |
| `Disabled` | Ready | `spec.enabled` is `false` — the deployment has been removed |
| `Creating` | Ready | The deployment was just created and may not be ready yet |
| `Updating` | Ready | The deployment is rolling out a new spec |
| `Ready` | Ready | The deployment is healthy — all replicas are available |
| `Unavailable` | Ready | The deployment is degraded — some replicas are unavailable |

```yaml
apiVersion: eevee.bot/v1
kind: BotModule
metadata:
  name: my-module
status:
  conditions:
    - type: Ready
      status: "True"
      reason: Ready
      message: "Deployment ready (1/1 replicas available)"
      lastTransitionTime: "2026-05-09T02:00:00Z"
```
