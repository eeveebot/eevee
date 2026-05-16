---
weight: 220
title: "Message Lifecycle"
description: "How a message travels through eevee.bot"
draft: false
toc: true
---

Every interaction with eevee.bot begins the same way: someone types something in a chat, and a small miracle of infrastructure carries their words across the void and back again. This page traces the full journey — from the moment a message arrives at a connector to the moment a reply appears on screen.

## A Message Is Born

It starts simply enough. A user sends a message to a chat channel on some platform — IRC, Discord, anywhere a connector is listening:

```none
<goos> !weather 12345
```

Just words on a screen. But the connector is watching.

## The Connector Listens

The appropriate connector module — say, `connector-irc` — receives the message from the platform and translates it into a standard format that the rest of eevee.bot can understand. Platform-specific quirks are stripped away. What remains is a structured JSON payload, published to NATS:

```json
{
  "type": "chat.message.incoming",
  "platform": "irc",
  "instance": "liberachat",
  "network": "irc.libera.chat",
  "channel": "#general",
  "nick": "goos",
  "user": "goosident",
  "userHost": "user/host",
  "text": "!weather 12345",
  "time": "2026-05-16T00:00:00.000Z",
  "account": "goosaccount",
  "botNick": "eevee",
  "commonPrefixRegex": "^[!~]"
}
```

The message is published to a NATS subject with the format:

```
chat.message.incoming.<platform>.<instance>.<channel>.<nick>
```

Connectors are the bridge between the outside world and eevee.bot's nervous system. Each platform gets its own connector, and each connector may manage multiple connections. They do the lonely work of translation — turning the chaos of IRC events and Discord gateway messages into something the router can reason about.

## The Router Decides

The `router` module subscribes to `chat.message.incoming.>` and receives every message that every connector publishes. It is the central intelligence of the system, and it has opinions.

### Blocklist

First, the router checks the message against the configured blocklist. Blocklist entries are regex patterns scoped by platform, network, instance, channel, or user. If a message matches, it is silently dropped. No command matching, no broadcasts, no second chances. Blocklist patterns are pre-compiled at config load time using the safe `compileRegex` helper (500 character limit, fallback to `/.^/` on failure).

### Command Matching

If the message survives the blocklist, the router checks it against all registered command patterns. For each command, the router:

1. Checks the scope filters (platform, network, instance, channel, user, nick) — all must match
2. Strips the platform prefix (e.g. `!`) or nick prefix (e.g. `eevee:`) if the command allows it
3. Matches the remaining text against the command's regex pattern

Each matching command triggers a `command.execute.<uuid>` message (subject to rate limiting — see below). Multiple commands can match a single message.

### Broadcast Matching

Independently, the router checks the message against all registered broadcast listeners. Broadcasts use the same scope filters but add an optional `messageFilterRegex` for content matching. Each matching broadcast triggers a `broadcast.message.<uuid>` message. Broadcasts are always delivered — they are not subject to rate limiting.

If a message matches neither a command nor a broadcast, it is dropped. Most messages are. The router is quietly selective.

### Command Execution Message

For each matched command, the router publishes to `command.execute.<commandUUID>`:

```json
{
  "platform": "irc",
  "network": "irc.libera.chat",
  "instance": "liberachat",
  "channel": "#general",
  "user": "goos",
  "nick": "goos",
  "userHost": "user/host",
  "text": "12345",
  "originalText": "!weather 12345",
  "matchedCommand": "!weather",
  "matchedText": "12345",
  "timestamp": "2026-05-16T00:00:00.000Z"
}
```

Note the distinction between `text` and `originalText` — the prefix has been stripped from `text`, while `originalText` preserves the full message. The `matchedText` field contains the text that was actually tested against the command regex.

### Broadcast Message

For each matched broadcast, the router publishes to `broadcast.message.<broadcastUUID>`:

```json
{
  "platform": "irc",
  "network": "irc.libera.chat",
  "instance": "liberachat",
  "channel": "#general",
  "user": "goos",
  "nick": "goos",
  "userHost": "user/host",
  "text": "!weather 12345",
  "timestamp": "2026-05-16T00:00:00.000Z"
}
```

Broadcast messages are always the full, unmodified text — no prefix stripping.

### Rate Limiting

Each command registration includes rate limit configuration. When a command would be executed but its rate limit has been exceeded, the router behaves differently depending on the configured `mode`:

- **`drop`** — the execution is silently discarded. No notification is sent to the user (unless a rate-limit notice is configured via the router's `notificationCooldown` setting, in which case an IRC NOTICE is sent to the user with a 15-second cooldown per user)
- **`enqueue`** — the execution is queued and will be processed when the rate limit resets. The user's message is not lost — it's just delayed

Rate limits are scoped by `level` — `user`, `channel`, `instance`, `platform`, or `global`. A per-user limit of 5 requests per minute means each user gets their own bucket. A global limit means the entire bot shares one.

## A Module Responds

The command execution message arrives at the target module, which subscribed to `command.execute.<uuid>` at startup. The module does whatever it needs to do — query a weather API, roll some dice, look up a definition. Then it sends a response.

Responses are published to `chat.message.outgoing.<platform>.<instance>.<channel>`:

```json
{
  "channel": "#general",
  "network": "irc.libera.chat",
  "instance": "liberachat",
  "platform": "irc",
  "text": "goos: the weather for 12345 is sunny and 72°F",
  "trace": "c4f8f2e5-0fbe-4511-a398-cb43393c2eed"
}
```

The `trace` field, when present, carries the original trace ID from the incoming message, allowing correlation between request and response in logs.

Modules use `sendChatMessage()` from `@eeveebot/libeevee` to construct and publish these messages. For IRC actions (`/me`), modules use `sendAction()` instead, which publishes to `chat.action.outgoing.<platform>.<instance>.<channel>`.

## The Connector Delivers

The connector subscribes to outgoing message subjects for its connections. When it receives the response, it sends it to the appropriate platform — the reverse of how it all started:

```none
<eevee> goos: the weather for 12345 is sunny and 72°F
```

And there it is. A message has traveled from a user, through a connector, across NATS, past the router's watchful eye, into a module that did some work, back across NATS, through the connector again, and out to the channel. The whole trip takes milliseconds. Nobody notices. That's the point.

## Passive Listeners

Not every message needs a response. Some modules observe without replying:

- **`seen`** tracks when users were last active — it registers a broadcast listener for all messages and quietly records timestamps
- **`urltitle`** detects URLs in messages and posts their titles — it uses a broadcast with `messageFilterRegex: "https?://"` to only receive messages containing links
- **`tell`** listens for delayed delivery commands — it uses a broadcast to observe messages and match tell/ask patterns

These modules never register commands. They live in the broadcast stream, watching and recording. The router treats them the same as any other broadcast subscriber — it just copies messages their way.

---

**Related:** See [Module Lifecycle](/docs/specification/module-lifecycle/) for how modules start up and shut down, [Command Registry](/docs/specification/command-registry/) for command registration details, [Broadcast Registry](/docs/specification/broadcast-registry/) for broadcast registration details, and [Writing a Module](/docs/guides/writing-a-module/) for a step-by-step guide to building a new module.
