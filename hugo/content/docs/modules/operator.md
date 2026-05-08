---
weight: 160
title: "operator"
description: "Kubernetes operator for managing eevee resources"
draft: false
---

The Operator module is a Kubernetes operator that manages eevee.bot custom resources. It watches for changes to **botmodule** and **ipcconfig** resources and ensures the appropriate Kubernetes deployments, services, and configurations are running.

## Features

- Manages **BotModule** custom resources for all eevee modules (connectors, plugins, toolbox)
- Manages **IpcConfig** custom resources for NATS inter-process communication
- Automatic deployment creation, update, and deletion for BotModule resources
- Managed NATS server deployment with automatic token generation
- Kubernetes Service creation for NATS connectivity
- ConfigMap management for module configuration
- PersistentVolumeClaim creation for stateful modules
- Secret injection for environment variables
- Operator API token mounting for admin-capable modules
- HTTP API server for module introspection and restart actions
- Prometheus metrics for both the operator and NATS deployments
- Cross-namespace resource management capabilities

## Custom Resources

The operator manages two custom resource types:

### BotModule (`eevee.bot/v1/botmodule`)

The BotModule CRD is the universal deployment mechanism for all eevee components. Every module — connectors (IRC, Discord), plugins (echo, calculator, dice, etc.), the router, and the toolbox — is deployed as a BotModule. The operator:

- Creates a `Deployment` named `eevee-<name>-module` for each BotModule
- Creates a `ConfigMap` with the module's YAML configuration (from `spec.moduleConfig`)
- Creates a `PersistentVolumeClaim` if `spec.persistentVolumeClaim` is set
- Injects NATS connection details from the referenced `IpcConfig`
- Injects secrets from `spec.envSecret` as environment variables
- Injects the operator API token if `spec.mountOperatorApiToken` is true
- Supports enabling/disabling modules via `spec.enabled`
- Handles updates by reconciling the deployment, config, and PVC

### IpcConfig (`eevee.bot/v1/ipcconfig`)

The IpcConfig CRD defines the NATS messaging infrastructure. The operator:

- Creates a NATS `Deployment` named `eevee-<name>-nats`
- Creates a `Service` for NATS client, management, and cluster ports
- Generates a random authentication token and stores it in a Kubernetes `Secret`
- Creates a `Secret` with the NATS server configuration file (`nats.conf`)
- Supports custom NATS container images via `spec.nats.managed.image`

## Health Probes

The operator automatically sets default health probes on module pods to ensure Kubernetes can detect and recover from unhealthy states:

| Probe | Type | Target | `initialDelaySeconds` | `periodSeconds` |
|-------|------|--------|----------------------|------------------|
| Liveness | HTTP GET | `/health` on `metricsPort` | 10 | 30 |
| Readiness | HTTP GET | `/health` on `metricsPort` | 5 | 10 |
| Startup | — | *(none — modules start fast)* | — | — |

The `/health` endpoint checks NATS connectivity. A pod that loses its NATS connection returns 503 and will be marked not ready by the readiness probe. If it stays unhealthy, the liveness probe will trigger a restart.

### Custom Probes

You can override the default probes by setting `livenessProbe`, `readinessProbe`, or `startupProbe` in the BotModule spec. These accept standard Kubernetes `V1Probe` objects (httpGet, tcpSocket, exec, etc.). When a custom probe is specified, it replaces the default entirely.

### Disabling Probes

If a module has `metrics: false` in its BotModule spec, no default probes are set. This is because the `/health` endpoint is served on the metrics port, which is not exposed when metrics are disabled.

## HTTP API

The operator exposes an HTTP API server (default port 9000) with the following endpoints:

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/` | No | Operator info and timestamp |
| GET | `/api/health` | Yes | Health check |
| GET | `/api/metrics` | No | Prometheus metrics |
| GET | `/api/bot-modules` | Yes | List all BotModules with image/tag info |
| POST | `/api/action/restart-module` | Yes | Rollout restart a module deployment |

Authenticated endpoints require a `Bearer` token matching the `EEVEE_OPERATOR_API_TOKEN` environment variable.

## Installation

The eevee Operator is installed using Helm:

```bash
helm repo add eevee https://helm.eevee.bot
helm repo update
helm install eevee-crds eevee/crds --namespace eevee-bot
helm install eevee-operator eevee/operator --namespace eevee-bot
```

## Configuration

The operator can be configured using environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `NAMESPACE` | `eevee-bot` | The namespace the operator should watch for CRs |
| `WATCH_OTHER_NAMESPACES` | `false` | Watch resources in namespaces other than the operator's namespace |
| `KUBE_IN_CLUSTER_CONFIG` | `false` | Use in-cluster Kubernetes configuration |
| `HTTP_API_PORT` | `9000` | Port for the HTTP API server |
| `EEVEE_OPERATOR_API_TOKEN` | *(none)* | API token for authenticated endpoints |

Helm values can also be used for configuration. See the chart documentation at [helm.eevee.bot](https://helm.eevee.bot/) for available options.

---

**Related:** See [Module Lifecycle](/docs/specification/module-lifecycle/) for how the operator manages module startup, health, updates, and shutdown.
