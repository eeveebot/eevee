---
weight: 512
title: "ipcconfig"
description: "eevee.bot/v1/ipcconfig"
draft: false
---

## `eevee.bot/v1/ipcconfig`

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
kind: ipcconfig
metadata:
  name: my-eevee-bot
  namespace: my-eevee-bot
spec:
  # Only NATS is supported for now
  nats:
    # Options for eevee-operator managed NATS
    managed:
      # Should the eevee-operator deploy a NATS server for us?
      enabled: true
      image: docker.io/nats:latest
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
