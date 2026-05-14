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
| `command.unregister` | Command unregistration requests from modules |
| `broadcast.unregister` | Broadcast unregistration requests from modules |
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
| `help.remove` | Remove help entries for a module |
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

Blocklist patterns are pre-compiled at config load time using a safe regex helper with a 500 character limit and fallback to `/.^/` on failure. Malformed patterns are logged and skipped rather than crashing the router.

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

## Rate Limiting

The router enforces per-command rate limits with configurable granularity (`platform`, `instance`, `channel`, `user`, or `global`). When a user exceeds their limit:
- **Drop mode**: The command is silently discarded
- **Enqueue mode**: The command is queued and processed when capacity is available. Before processing a queued command, the rate limiter re-checks whether the command is still allowed, preventing stale queued commands from bypassing limits

Rate limit notices are sent to users via IRC NOTICE with a 15-second cooldown per user to prevent notice spam.

## Monitoring

The router module exposes metrics on the configured metrics port (default: 8080) that provide insights into message routing performance and statistics.
