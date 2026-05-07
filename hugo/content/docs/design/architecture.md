---
weight: 100
title: "Architecture"
description: "How eevee.bot fits together — connectors, router, modules, operator, and NATS"
draft: false
toc: true
---

# Architecture Overview

eevee.bot is a microservices chatbot framework deployed on Kubernetes. Every component runs as an independent service, communicating exclusively through NATS message passing. A Kubernetes operator manages the lifecycle of all services via Custom Resource Definitions (CRDs).

## Core Components

### Connectors

Connectors bridge external chat platforms to the eevee.bot messaging system. Each connector maintains persistent connections to its platform and translates between platform-specific protocols and eevee.bot's internal message format.

- **connector-irc** — Connects to IRC networks using `irc-framework`. Supports multiple concurrent connections, SASL authentication, channel management, and hot-reloadable YAML configuration.
- **connector-discord** — Connects to Discord using `discord.js`. Supports multiple guilds and channels with Discord Gateway intents.

Connectors publish incoming chat messages to NATS subjects following the pattern:

```
chat.message.incoming.<platform>.<instance>.<channel>.<nick>
```

They subscribe to outgoing subjects to deliver bot responses:

```
chat.message.outgoing.<platform>.<instance>.>
```

### Router

The **router** is the central message dispatcher. It subscribes to `chat.message.incoming.>` and matches messages against registered command and broadcast patterns.

- **Command registration** — Modules register commands with a regex pattern. When a message matches, the router forwards it to the module via `command.execute.<UUID>`.
- **Broadcast registration** — Modules register broadcast listeners. Every incoming message is forwarded to all registered broadcast listeners via `broadcast.message.<UUID>`.
- **Blocklist** — The router maintains a configurable blocklist of users and channels to ignore.
- **Rate limiting** — Per-command rate limiting with configurable mode (enqueue/drop) and level (user/channel/global).

### Modules

Modules are the functional units that provide the bot's features. Each module:

1. Registers its commands and/or broadcasts with the router at startup
2. Subscribes to its `command.execute.<UUID>` and/or `broadcast.message.<UUID>` subjects
3. Processes messages and publishes responses to the appropriate outgoing NATS subject

Active modules include: admin, calculator, dice, echo, emote, help, seen, superslap, tell, urltitle, and weather.

### Operator

The **operator** is a Kubernetes operator that manages the lifecycle of all eevee.bot components. It watches two CRDs:

- **BotModule** — Defines a module deployment (image, config, resources, IPC access)
- **IpcConfig** — Defines a shared NATS + config Secret configuration that modules reference

The operator creates Deployments, mounts ConfigMaps and Secrets, and exposes an HTTP API for runtime operations like module restarts and status queries.

### CLI / Toolbox

The **cli** package provides the `eevee-monitor` tool for debugging. It subscribes to all NATS subjects and logs messages to stdout — useful for observing the full message flow in real time.

## Message Flow

```
IRC/Discord ──► Connector ──► NATS (chat.message.incoming.*)
                                       │
                                       ▼
                                    Router
                                    │    │
                    ┌───────────────┘    └───────────────┐
                    ▼                                     ▼
         command.execute.<UUID>              broadcast.message.<UUID>
                    │                                     │
                    ▼                                     ▼
              Command Module                         Broadcast Module
                    │                                     │
                    └──────────────┬──────────────────────┘
                                   ▼
                    NATS (chat.message.outgoing.*)
                                   │
                                   ▼
                              Connector ──► IRC/Discord
```

## NATS Subjects

| Subject | Direction | Description |
|---------|-----------|-------------|
| `chat.message.incoming.>` | Connector → Router | Incoming chat messages |
| `chat.message.outgoing.<platform>.<instance>.>` | Module → Connector | Outgoing bot responses |
| `command.register` | Module → Router | Register a command pattern |
| `broadcast.register` | Module → Router | Register a broadcast listener |
| `command.execute.<UUID>` | Router → Module | Dispatch a matched command |
| `broadcast.message.<UUID>` | Router → Module | Forward a message to broadcast listener |
| `control.registerCommands.<name>` | Router → Module | Request re-registration of commands |
| `control.registerBroadcasts.<name>` | Router → Module | Request re-registration of broadcasts |
| `admin.request.router` | Admin → Router | Administrative requests |
| `stats.emit.request` | Stats collection | Request module statistics |

## Shared Library

All modules depend on `@eeveebot/libeevee`, which provides:

- `NatsClient` — NATS connection wrapper
- `log` — Structured logger
- `handleSIG` — Graceful shutdown handler
- `initializeSystemMetrics` / `setupHttpServer` — Prometheus metrics
- `ircColors` — IRC formatting utilities

See the [libeevee-js module doc](../modules/libeevee-js/) for the full API reference.

## Deployment

All components are deployed as Kubernetes resources managed by the operator. The typical deployment flow:

1. Define an `IpcConfig` CR with NATS connection details and a Secret reference
2. Define `BotModule` CRs for each component, referencing the `IpcConfig`
3. The operator creates Deployments, mounts configs, and manages the lifecycle
4. Modules discover NATS and their configuration via environment variables injected by the operator

See the [operator module doc](../modules/operator/) and [quickstart guide](../quickstart/) for detailed setup instructions.
