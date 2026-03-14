---
weight: 130
title: "crds"
description: "Custom Resource Definitions for the eevee ecosystem"
draft: false
---

The CRDs module contains the Custom Resource Definitions (CRDs) for the eevee ecosystem. These definitions extend the Kubernetes API to support eevee-specific resources.

## Features

- Custom Resource Definitions for eevee ecosystem
- Extends Kubernetes API with eevee-specific resources
- Required for deploying eevee.bot with the Kubernetes operator

## Overview

The CRDs module defines the following custom resource types:

1. **ChatConnectionIrc** - Manages IRC chat connections
2. **IpcConfig** - Manages inter-process communication configurations
3. **Toolbox** - Manages toolbox configurations

These CRDs are prerequisites for using the eevee Operator to manage eevee.bot deployments.

## Installation

The CRDs are typically installed using Helm along with the eevee Operator:

```bash
helm repo add eevee https://helm.eevee.bot
helm repo update
helm install eevee-crds eevee/crds --namespace eevee-bot
```

## Configuration

The CRDs module is typically deployed as part of the operator installation and does not require individual configuration.