---
weight: 201
title: "connector-discord"
description: "Discord connectivity for eevee.bot"
draft: false
---

The Discord Connector bridges eevee.bot to Discord, enabling the platform to receive messages from Discord channels and send messages back through the Discord API. It connects to Discord using the [discord.js](https://discord.js.org/) library and communicates with the rest of the eevee ecosystem via NATS messaging. Each configured Discord bot instance runs as a separate `DiscordClient` within the connector.

## Features

- Connects to Discord using the discord.js library
- Supports multiple Discord bot instances from a single connector
- Receives messages from Discord channels and forwards them to the router via NATS
- Sends messages from the router to Discord channels
- Rich embed and direct message support
- Configurable Discord Gateway Intents
- Hot reloading of configuration files (via `chokidar` file watcher)
- Automatic reconnection on connection loss
- Uptime statistics reporting via NATS
- Graceful shutdown on `SIGINT` / `SIGTERM`

## Discord Intents

Intent strings in the config are mapped to `GatewayIntentBits` values:

| Config string | GatewayIntentBits |
|---|---|
| `GUILDS` | `GatewayIntentBits.Guilds` |
| `GUILD_MESSAGES` | `GatewayIntentBits.GuildMessages` |
| `GUILD_MESSAGE_REACTIONS` | `GatewayIntentBits.GuildMessageReactions` |
| `DIRECT_MESSAGES` | `GatewayIntentBits.DirectMessages` |
| `MESSAGE_CONTENT` | `GatewayIntentBits.MessageContent` |

If no intents are specified, the defaults are `GUILDS`, `GUILD_MESSAGES`, and `MESSAGE_CONTENT`.

## Hot Reload

Configuration is loaded from a YAML file and watched for changes using `chokidar`. When the file is modified, the connector automatically reloads — disconnecting and reconnecting all Discord clients with the new settings. No process restart is required.

## NATS Subjects

### Incoming

| Subject Pattern | Description |
|---|---|
| `chat.message.incoming.discord.<instance>.<channel>.<user>` | Incoming message from a Discord channel |
| `stats.uptime` | Uptime request — connector responds with its uptime |

### Outgoing

| Subject Pattern | Description |
|---|---|
| `chat.message.outgoing.discord.<instance}.>` | Send a message to a Discord channel (requires `channelId` and `text` fields) |

### Control

| Subject Pattern | Description |
|---|---|
| `control.connectors.discord.core.>` | General control messages for the connector |
| `control.chatConnectors.discord.<instance>` | Per-instance control messages (e.g. `send-message`) |

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  connector-discord                   │
│                                                      │
│  ┌──────────────┐        ┌────────────────────────┐ │
│  │  main.mts    │───┐    │  discord-client.mts     │ │
│  │              │   │    │                         │ │
│  │ • Config     │   └──▶│  DiscordClient           │ │
│  │   loading    │        │  ├─ connect()            │ │
│  │ • NATS setup │        │  ├─ say(channelId, msg) │ │
│  │ • File watch │        │  ├─ dm(userId, msg)     │ │
│  │ • SIG handler│        │  ├─ sendEmbed(ch, emb)  │ │
│  └──────────────┘        │  └─ quit(msg)           │ │
│         │                └────────┬────────────────┘ │
│         │                         │                  │
└─────────┼─────────────────────────┼──────────────────┘
          │                         │
          ▼                         ▼
      ┌───────┐              ┌──────────┐
      │ NATS  │              │ Discord  │
      │       │              │ Gateway  │
      └───────┘              └──────────┘
```

**Key components:**

- **`main.mts`** — Entry point. Loads YAML config, establishes the NATS connection, creates `DiscordClient` instances, subscribes to outgoing message subjects, and watches the config file for hot reloads.
- **`DiscordClient`** (`lib/discord-client.mts`) — Wraps the discord.js `Client`. Emits `message` and `connected` events. Provides `say()`, `dm()`, `sendEmbed()`, and `quit()` methods. Handles all Discord gateway events and filters out bot messages.

**Message flow:**

1. Discord user sends a message → `DiscordClient` emits `message` event → `main.mts` publishes to `chat.message.incoming.discord.*` NATS subject.
2. Another module publishes to `chat.message.outgoing.discord.<instance}.>` → `main.mts` receives it → calls `DiscordClient.say(channelId, text)` → message appears in Discord.

## Configuration

The Discord Connector is deployed as a botmodule with `moduleName: "discord"`. The Discord bot token is loaded from the `DISCORD_BOT_TOKEN` environment variable, which the eevee.bot operator provides by injecting a Kubernetes secret specified in the `envSecret` field.

First, create a Kubernetes secret containing your Discord bot token:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: discord-bot-token-secret
type: Opaque
data:
  DISCORD_BOT_TOKEN: <base64-encoded-bot-token>
```

Then reference this secret in your botmodule configuration:

```yaml
botModules:
- name: discord-connector
  spec:
    size: 1
    image: ghcr.io/eeveebot/connector-discord:latest
    pullPolicy: Always
    metrics: true
    metricsPort: 8080
    ipcConfig: my-eevee-bot
    moduleName: discord
    envSecret:
      name: discord-bot-token-secret
    moduleConfig: |
      connections:
      - name: my-discord-server
        ident:
          quitMsg: "eevee.bot shutting down"
        discord:
          token: "YOUR_BOT_TOKEN_HERE"
          intents:
            - "GUILDS"
            - "GUILD_MESSAGES"
            - "MESSAGE_CONTENT"
        postConnect: []
```
