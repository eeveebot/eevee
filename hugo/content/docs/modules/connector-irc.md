---
weight: 200
title: "connector-irc"
description: "IRC connectivity for eevee.bot"
draft: false
---

The IRC Connector bridges eevee.bot to IRC networks. It manages one or more IRC connections defined in a YAML configuration file, translates incoming IRC events (messages, actions, notices) into NATS messages for the router, and relays outgoing NATS messages back to IRC channels and users. Each IRC connection is identified by a unique name, and all NATS subjects include that name so downstream consumers can route messages to the correct instance.

## Features

- Multiple connections — connect to any number of IRC networks simultaneously from a single process
- Bidirectional messaging — supports privmsg, action (`/me`), and notice messages in both directions
- Hot config reload — watches the config file and reconnects automatically on changes
- Control channel — runtime join, part, kick, and user-list queries via NATS control messages
- Auto-reconnect and auto-rejoin — configurable retry behavior for network drops and channel kicks
- Post-connect actions — auto-join channels after connecting
- Prometheus metrics — message counters, connection gauges, channel gauges, error counters
- Uptime and stats reporting via NATS

## Hot Reload

Configuration is file-driven and **hot-reloaded**: when the YAML config file changes on disk, `chokidar` detects the change and connector-irc drains the NATS client (with a 3-second per-client timeout), disconnects all existing IRC clients, reconnects using the new settings, and recreates the NATS client so subscriptions are fresh. No process restart is required.

## NATS Subjects

### Incoming Messages (IRC → NATS)

| Subject | Description |
|---|---|
| `chat.message.incoming.irc.{name}.{channel}.{nick}` | Incoming privmsg or action from IRC |

### Outgoing Messages (NATS → IRC)

| Subject | Payload | Description |
|---|---|---|
| `chat.message.outgoing.irc.{name}.>` | `{ channel, text }` | Send a message to a channel/user |
| `chat.action.outgoing.irc.{name}.>` | `{ channel, text }` | Send a `/me` action |
| `chat.notice.outgoing.irc.{name}.>` | `{ channel, text }` | Send a notice to a channel |
| `chat.notice.outgoing.irc.{name}` | `{ target, text }` | Send a private notice to a user |

### Control Channel

Send JSON messages to `control.chatConnectors.irc.{name}` to control the bot at runtime:

**Join a channel:**

```json
{
  "action": "join",
  "data": { "channel": "#newchannel", "key": "optionalkey" }
}
```

**Part a channel:**

```json
{
  "action": "part",
  "data": { "channel": "#oldchannel" }
}
```

**Kick a user:**

```json
{
  "action": "kick",
  "data": { "channel": "#channel", "nick": "troublemaker", "reason": "optional reason" }
}
```

**List users in a channel:**

```json
{
  "action": "list-users-in-channel",
  "data": { "channel": "#channel", "replyChannel": "ephemeral.reply.subject" }
}
```

The user list response is published to the `replyChannel`:

```json
{
  "channel": "#channel",
  "users": [
    { "nick": "alice", "ident": "alice", "hostname": "user/host", "modes": ["o"], "isChannelAdmin": true }
  ],
  "count": 1
}
```

Each user object includes an `isChannelAdmin` boolean — `true` if the user has channel mode `+h` (halfop), `+o` (op), `+a` (admin/protect), or `+q` (owner).

If the NAMES response times out (10 seconds), an error response is sent:

```json
{
  "channel": "#channel",
  "error": "Timeout waiting for user list",
  "users": []
}
```

**Get modes for a user:**

```json
{
  "action": "get-modes-for-user",
  "data": { "channel": "#channel", "nick": "someuser", "replyChannel": "ephemeral.reply.subject" }
}
```

The modes response is published to the `replyChannel`:

```json
{
  "channel": "#channel",
  "nick": "someuser",
  "modes": ["o", "v"],
  "isChannelAdmin": true
}
```

If the user is not found in the channel:

```json
{
  "channel": "#channel",
  "nick": "someuser",
  "modes": [],
  "isChannelAdmin": false,
  "warning": "User not found in channel"
}
```

If the WHO query times out (5 seconds):

```json
{
  "channel": "#channel",
  "nick": "someuser",
  "modes": [],
  "isChannelAdmin": false,
  "error": "Timeout waiting for user modes"
}
```

This action sends a WHO query to the IRC server every time (no caching) to ensure fresh, authoritative mode data.

### Stats Subjects

| Subject | Description |
|---|---|
| `stats.uptime` | Responds with module uptime via `replyChannel` |
| `stats.emit.request` | Responds with full stats (uptime, memory, Prometheus metrics, connector details) via `replyChannel` |
| `control.connectors.irc.core.>` | Logs core control messages |

The `stats.emit.request` response includes a `connector` array with per-connection health details:

```json
{
  "module": "connector-irc",
  "stats": {
    "version": "1.7.1",
    "connector": [
      {
        "name": "liberachat",
        "connected": true,
        "host": "irc.libera.chat",
        "nick": "mybot",
        "channels": 3,
        "reconnects": 0,
        "lastConnect": "2026-05-16T00:00:00.000Z",
        "lastDisconnect": null
      }
    ]
  }
}
```

The `admin health` command uses this data to display connection status, flag disconnected connectors as degraded, and show reconnect history.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                   connector-irc                      │
│                                                      │
│  ┌──────────────┐    ┌──────────────┐               │
│  │  IrcClient   │    │  IrcClient   │  ...          │
│  │  (liberachat)│    │  (oftc)      │               │
│  └──────┬───────┘    └──────┬───────┘               │
│         │                   │                        │
│    privmsg/action      privmsg/action                │
│    events              events                       │
│         │                   │                        │
│         ▼                   ▼                        │
│  ┌─────────────────────────────────┐                │
│  │          main.mts               │                │
│  │  ┌────────────┐ ┌────────────┐  │                │
│  │  │  chokidar  │ │  express   │  │                │
│  │  │  (config   │ │  (metrics  │  │                │
│  │  │   reload)  │ │   HTTP)    │  │                │
│  │  └────────────┘ └────────────┘  │                │
│  └──────────────┬──────────────────┘                │
│                 │                                    │
└─────────────────┼────────────────────────────────────┘
                  │ NATS
                  ▼
         ┌──────────────┐
         │    router     │  →  command modules
         └──────────────┘
```

**Key components:**

- **`main.mts`** — Entry point. Sets up NATS, reads config, creates `IrcClient` instances, wires event handlers, subscribes to outgoing and control NATS subjects, watches the config file for changes.
- **`IrcClient`** (`lib/irc-client.mts`) — Wraps `irc-framework`'s `Client` with eevee-specific concerns: status tracking, channel management, Prometheus metrics, and EventEmitter passthrough of all IRC events.

## Configuration

The IRC Connector is deployed as a botmodule with `moduleName: "irc"`:

```yaml
botModules:
- name: irc-connector
  spec:
    size: 1
    image: ghcr.io/eeveebot/connector-irc:latest
    pullPolicy: Always
    metrics: true
    metricsPort: 8080
    ipcConfig: my-eevee-bot
    moduleName: irc
    moduleConfig: |
      connections:
      - name: my-irc-network
        irc:
          host: irc.my-irc-network.local
          port: 6667
          ssl: true
          autoReconnect: true
          autoReconnectWait: 5000
          autoReconnectMaxRetries: 10
          autoRejoin: true
          autoRejoinWait: 5000
          autoRejoinMaxRetries: 5
          pingInterval: 30
          pingTimeout: 120
        ident:
          nick: eevee
          username: eevee
          gecos: eevee.bot
          version: "0.4.20"
          quitMsg: "eevee v0.4.20"
        postConnect:
          - action: join
            join:
              - channel: '#bots'
              - channel: '#cool-kids-club'
        commands:
          commonPrefixRegex: "^-"
```

### IRC Settings

| Key | Type | Default | Description |
|---|---|---|---|
| `host` | string | `localhost` | IRC server hostname |
| `port` | number/string | `6667` | IRC server port |
| `ssl` | boolean | `false` | Enable TLS |
| `autoReconnect` | boolean | `true` | Reconnect on disconnect |
| `autoReconnectMaxRetries` | number | `10` | Max reconnect attempts |
| `autoReconnectWait` | number | `5000` | Milliseconds between retries |
| `autoRejoin` | boolean | `true` | Rejoin channels after kick |
| `autoRejoinMaxRetries` | number | `5` | Max rejoin attempts |
| `autoRejoinWait` | number | `5000` | Milliseconds between rejoin retries |
| `pingInterval` | number | `30` | Seconds between keepalive pings |
| `pingTimeout` | number | `120` | Seconds before ping timeout |

### Identity Settings

| Key | Type | Default | Description |
|---|---|---|---|
| `nick` | string | `eevee` | Bot nickname |
| `username` | string | `eevee` | IRC username/ident |
| `gecos` | string | `eevee.bot` | Real name (GECOS) field |
| `quitMsg` | string | — | Quit message (required) |
| `version` | string | connector version | CTCP VERSION response |

### Post-Connect Actions

Each entry has an `action` field. Currently only `join` is supported:

```yaml
postConnect:
- action: join
  join:
  - channel: '#general'
  - channel: '#private'
    key: channelkey
```
