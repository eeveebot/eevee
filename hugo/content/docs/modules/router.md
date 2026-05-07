---
weight: 125
title: "router"
description: "Message routing, command dispatch, and broadcast distribution for eevee.bot"
draft: false
---

# router

The Router module is the central message hub for eevee.bot. It receives incoming chat messages from connectors, matches them against registered commands and broadcast listeners, applies blocklist filtering and rate limiting, and dispatches matched messages to the appropriate modules.

## Features

- Centralized incoming message routing
- Command registration and matching via regex patterns
- Broadcast registration and message distribution
- Configurable blocklist for filtering messages by platform, network, instance, channel, or user
- Per-command rate limiting with enqueue or drop modes
- Admin API for introspecting command registry and rate limit statistics
- Stats reporting (uptime, memory, Prometheus metrics)
- Prometheus metrics for message processing, command matching, and NATS operations

## NATS Subscriptions

The router subscribes to the following NATS subjects:

| Subject | Purpose |
|---------|---------|
| `chat.message.incoming.>` | Incoming messages from chat connectors |
| `command.register` | Command registration requests from modules |
| `broadcast.register` | Broadcast registration requests from modules |
| `admin.request.router` | Admin requests for rate limit stats and command registry |
| `stats.emit.request` | Requests for module stats (uptime, memory, metrics) |
| `stats.uptime` | Requests for module uptime |

## NATS Publications

The router publishes to the following subjects:

| Subject | Purpose |
|---------|---------|
| `command.execute.<commandUUID>` | Dispatch matched command to the registering module |
| `broadcast.message.<broadcastUUID>` | Deliver broadcast message to the registering module |
| `control.registerCommands` | Prompt modules to re-register commands (TTL-based) |
| `control.registerBroadcasts` | Prompt modules to re-register broadcasts (TTL-based) |
| `admin.response.router.*` | Admin response messages |
| `stats.response.<replyChannel>` | Stats response messages |

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
      blocklist:
      - pattern: ".*"
        enabled: true
        description: "Ignore all from fishy-bot"
        platform: "irc"
        instance: "irc-wetfish-net"
        user: "fishy.*"
```

### Blocklist Configuration

The router supports a blocklist to filter out messages from specific sources. Each blocklist entry is a set of regex patterns — if all provided patterns match, the message is dropped.

| Field | Type | Description |
|-------|------|-------------|
| `pattern` | string | Regex pattern to match against message text |
| `enabled` | boolean | Whether this entry is active (default: true) |
| `description` | string | Human-readable description |
| `platform` | string | Regex to match the platform (e.g., `^irc$`) |
| `network` | string | Regex to match the network |
| `instance` | string | Regex to match the connection instance |
| `channel` | string | Regex to match the channel |
| `user` | string | Regex to match the user |

## Monitoring

The router module exposes metrics on the configured metrics port (default: 8080) that provide insights into message routing performance and statistics.
