---
weight: 160
title: "operator"
description: "Kubernetes operator for managing eevee resources"
draft: false
---

The Operator module is a Kubernetes operator that manages eevee.bot custom resources. It watches for changes to ChatConnectionIrc, IpcConfig, and Toolbox resources and ensures the appropriate Kubernetes deployments are running.

## Features

- Manages ChatConnectionIrc custom resources for IRC connections
- Manages IpcConfig custom resources for inter-process communication
- Manages Toolbox custom resources for monitoring and utilities
- Automatic deployment and scaling of eevee.bot components
- Cross-namespace resource management capabilities

## Overview

This operator manages three custom resource types:

1. **ChatConnectionIrc** - Manages IRC chat connections
2. **IpcConfig** - Manages inter-process communication configurations
3. **Toolbox** - Manages toolbox configurations

For each custom resource created in the cluster, the operator creates and maintains the necessary Kubernetes deployments to run the corresponding eevee components.

## Installation

The eevee Operator is installed using Helm:

```bash
helm repo add eevee https://helm.eevee.bot
helm repo update
helm install eevee-operator eevee/operator --namespace eevee-bot
```

## Configuration

The operator can be configured using environment variables:

- `NAMESPACE` - The namespace the operator should watch (default: "eevee-bot")
- `WATCH_OTHER_NAMESPACES` - Whether to watch resources in namespaces other than the operator's namespace (default: "false")

Helm values can also be used for configuration. See the chart documentation at [helm.eevee.bot](https://helm.eevee.bot/) for available options.