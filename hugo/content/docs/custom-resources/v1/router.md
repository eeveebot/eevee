---
weight: 512
title: "router"
description: "eevee.bot/v1/router"
draft: false
---

## `eevee.bot/v1/router`

This file defines a Custom Resource for the router component in the eevee.bot/v1 API. It shows how to configure the router with settings such as:

- Number of instances to run
- Container image to use
- Image pull policy
- Metrics configuration
- IPC configuration reference
- Arbitrary router configuration

The router CRD allows you to define and deploy the routing component that manages message distribution between bot modules.

```yaml
---
apiVersion: eevee.bot/v1
kind: router
metadata:
  name: my-router
  namespace: my-eevee-bot
spec:
  size: 1
  image: ghcr.io/eeveebot/router:latest
  pullPolicy: Always
  metrics: false
  metricsPort: 8080
  ipcConfig: my-eevee-bot
  moduleConfig:
    # Arbitrary configuration passed to the router
    setting1: value1
    setting2: value2
```

## Specification

### Properties

#### `size` (integer)
Size defines the number of router instances
Default: 1

#### `image` (string)
Image defines the container image to use
Default: "ghcr.io/eeveebot/router:latest"

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

#### `moduleConfig` (object)
ModuleConfig is a passthrough field for arbitrary YAML configuration that will be passed directly to the router