---
weight: 310
title: "Overview: eevee-operator"
description: "Why the hell did you write an operator"
draft: false
toc: true
---

## Introduction

This document describes the eevee Kubernetes Operator, a custom controller designed to manage the lifecycle of the chat utility bot eevee within a Kubernetes environment.
The operator facilitates the deployment, configuration, scaling, and updates of eevee by consuming and interpreting Custom Resource Definitions (CRDs).

## Key Features

### Custom Resource Definitions (CRDs)

The eevee Operator consumes CRDs that encapsulate the configuration and operational requirements of the eevee chat utility bot.
The CRDs define various settings that influence the behavior and deployment of the bot, including:

- **BotModule Configuration**: Deploys and manages all eevee modules (connectors, plugins, router, toolbox) as BotModule custom resources:
  - Container image and replica count
  - Module-specific YAML configuration (passed via ConfigMap)
  - Persistent storage (PersistentVolumeClaim)
  - Secret injection for environment variables
  - Operator API token mounting for admin-capable modules
  - Enable/disable toggle
- **Infrastructure Configuration**: Specifications for the underlying messaging infrastructure:
  - NATS server deployment with token authentication
  - Kubernetes Service for NATS connectivity

### Lifecycle Management

The eevee Operator automates the lifecycle management of the eevee chat utility bot:

- **Deployment**: Initializes and configures modules and NATS within the Kubernetes cluster according to the specified CRD settings.
- **Configuration**: Applies updates to module configuration dynamically without downtime by updating ConfigMaps and reconciling deployments.
- **Scaling**: Manages the scaling of module instances based on the `size` field in BotModule specs.
- **Updates**: Seamlessly applies image updates to modules while ensuring minimal disruption to service availability.

### Monitoring and Logging

The eevee Operator leverages Kubernetes monitoring tools and integrates with logging frameworks to provide visibility into the bot's performance and operational health. This includes:

- **Custom Metrics**: Exposes custom metrics via Prometheus for both the operator itself and managed deployments.
- **Logging**: Integrates with centralized logging systems to capture detailed logs for diagnostic and auditing purposes.

### HTTP API

The operator exposes an HTTP API server that provides:

- **Module introspection**: List all BotModules with their image and tag information
- **Module restart**: Trigger rollout restarts for module deployments
- **Health and metrics**: Health check and Prometheus metrics endpoints

### Fault Tolerance and Recovery

The eevee Operator incorporates mechanisms to ensure fault tolerance and facilitate recovery from failures:

- **Self-healing**: Automatically reconciles BotModule and IpcConfig resources, ensuring deployments match the desired state.
- **Backup and Restore**: Compatible with standard Kubernetes backup and restore tooling such as Velero.

## Architecture

The architecture of the eevee Operator is designed to be fairly standard, following the typical Kubernetes Operator patterns.

- **Controller**: The primary component responsible for reconciling the desired state of the eevee bot as defined by the CRDs with the actual state in the Kubernetes cluster.
- **CRDs**: Two custom resource definitions — `BotModule` and `IpcConfig` — that serve as configuration templates for the eevee bot.
- **API Server**: The central Kubernetes API server that interacts with the operator to send requests and receive responses.
- **Etcd**: The distributed key-value store used by Kubernetes to store the state of the cluster, including the CRDs managed by the eevee Operator.

## Usage

To deploy and configure the eevee chat utility bot using the eevee Kubernetes Operator, follow these steps:

1. **Install the CRDs**: Deploy the CRD definitions within the Kubernetes cluster using the eevee-crds Helm chart.
2. **Install the Operator**: Deploy the operator within the Kubernetes cluster using the eevee-operator Helm chart.
3. **Create IpcConfig**: Define an IpcConfig resource to set up NATS messaging infrastructure.
4. **Create BotModules**: Define BotModule resources for each eevee component (connectors, plugins, router, toolbox).
5. **Monitor and Manage**: Use the operator's HTTP API, Kubernetes monitoring tools, and logs to monitor performance and make adjustments through CRD updates.
