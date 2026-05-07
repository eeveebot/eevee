---
weight: 100
title: "echo"
description: "Simple message echoing functionality for eevee.bot"
draft: false
---

The Echo module provides simple message echoing functionality for eevee.bot. It listens for messages beginning with `echo ` and responds by sending the same text back to the originating channel. While it's the simplest eevee command module, it's also the canonical reference implementation — a fully production-grade module with NATS-based messaging, Prometheus metrics, configurable rate limiting, health checks, and graceful shutdown.

## Architecture

Echo operates as a standard command module in the NATS message bus. When a user types `echo <text>` in any connected channel, the router matches the command regex (`^echo\s+`) and publishes a `command.execute` message. The echo module picks it up, extracts the text, and publishes a chat message back through the connector.

```
User types "echo hello"
        │
        ▼
   Chat Connector (IRC/Discord)
        │
        ▼
   Router — regex match: ^echo\s+
        │
        ▼
   NATS: command.execute.<UUID>
        │
        ▼
   Echo Module
   ├── Parse JSON message
   ├── Extract text, channel, network, platform
   ├── Publish chat message via NATS
   └── Record metrics (success/error, processing time)
        │
        ▼
   Chat Connector → sends "hello" back to channel
```

### NATS Subjects

| Subject | Direction | Purpose |
|---------|-----------|---------|
| `control.registerCommands` | Publish | Registers the echo command with the router |
| `command.execute.<UUID>` | Subscribe | Receives matched command invocations |
| `chat.send` | Publish | Sends the echoed text back to the channel |
| `help.register.echo` | Publish | Registers help entries |
| `help.update` | Subscribe | Responds to help refresh requests |
| `stats.uptime` | Subscribe | Reports module uptime |
| `stats.emit.request` | Subscribe | Emits full stats snapshot on demand |

## Features

- Message echoing with verbatim text reproduction
- Configurable rate limiting (per-user or per-channel)
- Automatic command and help registration via `@eeveebot/libeevee`
- Prometheus metrics (command counts, processing time, NATS subscribe counts)
- Health checks via HTTP endpoint (Kubernetes-ready)
- Uptime tracking and on-demand stats emission
- Graceful shutdown with NATS connection draining

## Usage

Send a message beginning with `echo` to any channel where the bot is present (providing any platform prefix if required):

```none
!echo Hello, world!
```

The bot will respond with:

```none
Hello, world!
```

The command matches on the regex `^echo\s+`, so any message starting with `echo ` (with at least one space) will trigger it. The matched text after `echo ` is echoed verbatim.

## Configuration

To deploy the echo module, add it to your bot's `botModules` configuration with `moduleName: "echo"`:

```yaml
botModules:
- name: echo
  spec:
    size: 1
    image: ghcr.io/eeveebot/echo:latest
    pullPolicy: Always
    metrics: true
    metricsPort: 8080
    ipcConfig: my-eevee-bot
    moduleName: echo
    moduleConfig: |
      ratelimit:
        mode: drop
        level: user
        limit: 5
        interval: 1m
```

### Rate Limiting

The rate limiting configuration supports the following options:

| Key | Values | Description |
|-----|--------|-------------|
| `mode` | `drop` or `queue` | `drop` silently ignores excess invocations; `queue` buffers and delays them |
| `level` | `user` or `channel` | Rate limit granularity — per-user or per-channel |
| `limit` | integer | Maximum allowed invocations per interval |
| `interval` | duration string | Time window (e.g. `30s`, `5m`, `1h`) |

If no configuration file is provided, the module uses libeevee's default rate limiting settings.
