---
weight: 512
title: "eevee.bot/v1/ipcConfig"
description: ""
draft: false
---

## `eevee.bot/v1/ipcConfig`

This file defines a Custom Resource example for IPC (Inter-Process Communication) configuration in the eevee.bot/v1 API. It shows how to configure a bot named "my-eevee-bot" to use NATS as its messaging system with settings such as:

- Managed NATS deployment through eevee-operator
- Resource allocation for the NATS container (CPU, memory limits/requests)
- Environment variables including GOMEMLIMIT and authentication tokens
- NATS server configuration including ports, clustering, and JetStream settings
- Monitoring and metrics export configuration
- Service exposure settings for various NATS protocols
- Automatic token generation for authentication
- Reference to Kubernetes secrets for secure token storage

The example demonstrates advanced features like referencing secrets for sensitive data (authentication tokens) and configuring various NATS subsystems.
It also enables monitoring endpoints and sets up proper resource limits for stable operation.

```yaml
---
apiVersion: eevee.bot/v1
kind: ipcConfig
metadata:
  name: my-eevee-bot
  namespace: my-eevee-bot
spec:
  # Only NATS is supported for now
  nats:
    # Options for eevee-operator managed NATS
    managed:
      # Should the eevee-operator deploy a NATS cluster for us?
      enabled: true
      # NATS deployment config
      spec:
        #
        # See https://artifacthub.io/packages/helm/nats/nats for full configuration options
        #
        namespaceOverride: my-eevee-bot
        container:
          env:
            # Different from k8s units, suffix must be B, KiB, MiB, GiB, or TiB
            # Should be ~80% of memory limit
            GOMEMLIMIT: 3.5GiB
            TOKEN:
              valueFrom:
                secretKeyRef:
                  name: nats-auth
                  key: token
          merge:
            resources:
              requests:
                cpu: "2"
                memory: 4Gi
              limits:
                cpu: "2"
                memory: 4Gi
        config:
          cluster:
            enabled: false
            port: 6222
            # must be 2 or higher when jetstream is enabled
            replicas: 1
          jetstream:
            enabled: false
            fileStore:
              enabled: false
              pvc:
                enabled: false
            memoryStore:
              enabled: true
          nats:
            port: 4222
          leafnodes:
            enabled: false
          websocket:
            enabled: false
          mqtt:
            enabled: false
          gateway:
            enabled: false
          monitor:
            enabled: true
            port: 8222
          profiling:
            enabled: false
            port: 65432
          resolver:
            enabled: false
          merge:
            authorization:
              token: << $TOKEN >>
          patch: []
        reloader:
          enabled: true
        promExporter:
          enabled: true
          podMonitor:
            enabled: true
        service:
          enabled: true
          ports:
            nats:
              enabled: true
            leafnodes:
              enabled: true
            websocket:
              enabled: true
            mqtt:
              enabled: true
            cluster:
              enabled: true
            gateway:
              enabled: true
            monitor:
              enabled: true
            profiling:
              enabled: true
        # pod disruption budget
        podDisruptionBudget:
          enabled: true
        # service account
        serviceAccount:
          enabled: true
        natsBox:
          enabled: false # eevee-toolbox has NATS client included

    # Options for NATS token auth
    token:
      # Should the eevee-operator generate a token for NATS auth?
      generate: true
      # Where to access the NATS auth token
      secretKeyRef:
        secret:
          name: my-irc-network-secrets
        key: token
```
