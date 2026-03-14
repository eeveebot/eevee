---
weight: 215
title: "Broadcast Registry"
description: "How modules can listen to all messages in eevee.bot"
draft: false
toc: true
---

Modules can register to receive copies of all messages that match specific criteria through the broadcast registry system. This is useful for modules that need to monitor chat activity without necessarily responding to specific commands.

Broadcast listeners are ideal for modules that need to:

- Log or analyze chat activity across multiple channels or platforms
- Track user behavior or engagement metrics
- Monitor for specific keywords or patterns in conversations
- Implement features like presence detection or activity tracking

Unlike command handlers that respond to specific triggers, broadcast listeners receive copies of all messages that match their registration criteria, enabling passive observation of chat traffic.

## Broadcast Registration Schema

Each module registers for broadcasts by publishing a message to the `broadcast.register` subject with the following structure:

```json
{
  "type": "broadcast.register",
  "broadcastUUID": "unique-uuid-for-this-broadcast",
  "broadcastDisplayName": "Optional display name for logs and UI",
  "platform": "regex-pattern-for-platform",
  "network": "regex-pattern-for-network",
  "instance": "regex-pattern-for-instance",
  "channel": "regex-pattern-for-channel",
  "user": "regex-pattern-for-user",
  "messageFilterRegex": "optional-regex-to-filter-message-content",
  "ttl": 3600000
}
```

### Field Descriptions

- `type`: Must be `"broadcast.register"`
- `broadcastUUID`: A unique UUID for this broadcast registration
- `broadcastDisplayName`: Optional display name for logs and UI
- `platform`: Regex pattern to match the platform (e.g., `"^irc$"`, `"^discord$"`, `"^.*$"`)
- `network`: Regex pattern to match the network within the platform
- `instance`: Regex pattern to match the connection instance
- `channel`: Regex pattern to match the channel
- `user`: Regex pattern to match the user
- `messageFilterRegex`: Optional regex pattern to filter messages by content
- `ttl`: Optional time-to-live in milliseconds for automatic expiration of the registration (default: 120000ms)

## Example Broadcast Registrations

### Global Message Logger

This broadcast listener receives all messages across all platforms:

```json
{
  "type": "broadcast.register",
  "broadcastUUID": "5f4b8c6a-9d2e-4f1a-8c3b-7a2d9e8f1c4a",
  "broadcastDisplayName": "Global Message Logger",
  "platform": "^.*$",
  "network": "^.*$",
  "instance": "^.*$",
  "channel": "^.*$",
  "user": "^.*$",
  "ttl": 3600000
}
```

This example uses `^.*$` patterns to match everything, making it a global listener. The TTL is set to 3600000ms (1 hour), which is much longer than the default, ensuring the registration persists for extended logging sessions.

### IRC Channel Monitor

This broadcast listener receives all messages in IRC channels matching a specific pattern:

```json
{
  "type": "broadcast.register",
  "broadcastUUID": "8d7c9b3a-2e4f-4a1b-9c3d-6e2f8a1b4c7d",
  "broadcastDisplayName": "IRC Channel Monitor",
  "platform": "^irc$",
  "network": "^.*$",
  "instance": "^.*$",
  "channel": "^#general$",
  "user": "^.*$",
  "messageFilterRegex": ".*(error|warning|critical).*",
  "ttl": 3600000
}
```

This example demonstrates more targeted listening. It only receives messages from the IRC platform in the #general channel, and further filters messages using a regex pattern to only receive those containing error, warning, or critical keywords. This is useful for monitoring important system messages in a specific channel.

### User Activity Tracker

This broadcast listener receives all messages from specific users:

```json
{
  "type": "broadcast.register",
  "broadcastUUID": "2a4b6c8d-1e3f-4b2a-8d3c-5e2f7a1b9c4d",
  "broadcastDisplayName": "User Activity Tracker",
  "platform": "^.*$",
  "network": "^.*$",
  "instance": "^.*$",
  "channel": "^.*$",
  "user": "^important_user$",
  "ttl": 3600000
}
```

This example shows how to track messages from a specific user across all platforms, networks, instances, and channels. This could be useful for monitoring important users.

## Broadcast Message Delivery

When a message matches a registered broadcast listener, the router publishes the message to the subject `broadcast.message.$broadcastUUID` with the following structure:

```json
{
  "platform": "irc",
  "network": "thegooscloud",
  "instance": "eevee",
  "channel": "#general",
  "user": "goos",
  "userHost": "honk.com",
  "text": "!weather 12345",
  "timestamp": "2023-01-01T00:00:00.000Z"
}
```

## Automatic Re-registration

Broadcast registrations automatically expire after their TTL period. To prevent gaps in message delivery, the router will prompt modules to re-register broadcasts approximately halfway through their TTL by publishing to:

- `control.registerBroadcasts` (general prompt)
- `control.registerBroadcasts.$broadcastDisplayName` (specific prompt, if displayName is provided)

Modules should subscribe to these subjects and re-register their broadcasts when prompted.

## Storage

The registry component of the router stores these registrations in memory with automatic cleanup based on TTL. At runtime, it performs lookups based on these registrations to determine which broadcasts should receive each incoming message.
