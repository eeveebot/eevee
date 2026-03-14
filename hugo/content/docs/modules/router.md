---
weight: 125
title: "router"
description: "Message routing for eevee.bot using the botmodule CRD"
draft: false
---

# router

The Router module provides message routing functionality for eevee.bot using the botmodule CRD. It acts as a central hub that routes messages between different modules and platforms in the eevee.bot ecosystem.

## Features

- Centralized message routing
- Cross-module communication
- Platform-agnostic message handling
- Configurable routing rules
- Message filtering and transformation

## Configuration

The Router is deployed as a botmodule with `moduleName: "router"`. The router configuration is specified in the `moduleConfig` field.

Example configuration:

```yaml
botModules:
- name: router
  spec:
    size: 1
    image: ghcr.io/eeveebot/router:latest
    pullPolicy: Always
    metrics: true
    metricsPort: 8080
    ipcConfig: my-eevee-bot
    moduleName: router
    moduleConfig: |
      {}
```

## Functionality

The router module listens for messages on various NATS subjects and routes them appropriately based on the message type and destination. It enables different modules to communicate with each other without needing direct connections.

Common message patterns that the router handles include:

- `messages.inbound.*` - Incoming messages from chat platforms
- `messages.outbound.*` - Outgoing messages to chat platforms
- `commands.register` - Command registration requests
- `commands.execute.*` - Command execution requests

## Monitoring

The router module exposes metrics on the configured metrics port (default: 8080) that provide insights into message routing performance and statistics.
