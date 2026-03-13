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

The botmodule CRD allows you to define and deploy individual bot modules that communicate through the eevee.bot messaging system.

```yaml
---
apiVersion: eevee.bot/v1
kind: botmodule
metadata:
  name: my-module
  namespace: my-eevee-bot
spec:
  size: 1
  image: ghcr.io/eeveebot/module:latest
  pullPolicy: Always
  metrics: false
  metricsPort: 8080
  ipcConfig: my-eevee-bot
  moduleName: my-module
  persistentVolumeClaim:
    accessModes:
    - ReadWriteOnce
    resources:
      requests:
        storage: 1Gi
  volumeMountPath: /data
  moduleConfig:
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
Default: 8080

#### `ipcConfig` (string)
IPC configuration name

#### `moduleName` (string)
ModuleName defines the name of the module

#### `persistentVolumeClaim` (object)
PersistentVolumeClaim defines the PVC configuration for the module

#### `volumeMountPath` (string)
VolumeMountPath defines where to mount the PVC in the container
Default: "/data"

#### `moduleConfig` (object)
ModuleConfig is a passthrough field for arbitrary YAML configuration that will be passed directly to the module
