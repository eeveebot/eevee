---
weight: 210
title: "Command Registry"
description: "How modules register to handle specific commands in eevee.bot"
draft: false
toc: true
---

Modules register commands they want to handle messages for as follows:

Command registration allows modules to declare which messages they can process based on various criteria including the message content, platform, network, channel, and user. This flexible system enables precise control over when and where commands are triggered.

When a message matches a registered command pattern, the router automatically routes it to the appropriate module for processing. This approach allows for distributed command handling across multiple modules while maintaining centralized routing logic.

## Command Registration Schema

Each module registers commands by publishing a message to the `command.register` subject with the following structure:

```json
{
  "type": "command.register",
  "commandUUID": "unique-uuid-for-this-command",
  "commandDisplayName": "Optional display name for logs and UI",
  "platform": "regex-pattern-for-platform",
  "network": "regex-pattern-for-network",
  "instance": "regex-pattern-for-instance",
  "channel": "regex-pattern-for-channel",
  "user": "regex-pattern-for-user",
  "regex": "regex-pattern-for-the-command-itself",
  "platformPrefixAllowed": true,
  "nickPrefixAllowed": true,
  "ratelimit": {
    "mode": "enqueue|drop",
    "level": "platform|instance|channel|user|global",
    "limit": 10,
    "interval": "30s"
  },
  "ttl": 3600000
}
```

### Field Descriptions

- `type`: Must be `"command.register"`
- `commandUUID`: A unique UUID for this command registration
- `commandDisplayName`: Optional display name for logs and UI
- `platform`: Regex pattern to match the platform (e.g., `"^irc$"`, `"^discord$"`, `"^.*$"`)
- `network`: Regex pattern to match the network within the platform
- `instance`: Regex pattern to match the connection instance
- `channel`: Regex pattern to match the channel
- `user`: Regex pattern to match the user
- `regex`: Regex pattern to match the command itself
- `platformPrefixAllowed`: Whether the platform's common prefix is allowed for this command
- `nickPrefixAllowed`: Whether the bot's nickname can be used as a prefix for this command
- `ratelimit`: Rate limiting configuration (set to `false` to disable)
  - `mode`: How to handle rate limited commands (`"enqueue"` or `"drop"`)
  - `level`: Scope of rate limiting (`"platform"`, `"instance"`, `"channel"`, `"user"`, or `"global"`)
  - `limit`: Number of allowed commands within the interval
  - `interval`: Time interval for rate limiting (e.g., `"30s"`, `"1m"`, `"5m"`)
- `ttl`: Optional time-to-live in milliseconds for automatic expiration of the registration

## Example Command Registrations

### Weather Command

This command matches messages like:

- `!weather 12345`
- Works across all platforms, networks, instances, and channels.

```json
{
  "type": "command.register",
  "commandUUID": "d462389d-a4f5-4d38-b738-3fa2ae89c2ad",
  "commandDisplayName": "Weather Lookup",
  "platform": "^.*$",
  "network": "^.*$",
  "instance": "^.*$",
  "channel": "^.*$",
  "user": "^.*$",
  "regex": "^weather (0-9a-z)+$",
  "platformPrefixAllowed": true,
  "nickPrefixAllowed": false,
  "ratelimit": {
    "mode": "enqueue",
    "level": "channel",
    "limit": 10,
    "interval": "30s"
  },
  "ttl": 3600000
}
```

This example shows a globally available weather command that can be used anywhere. The regex pattern `^weather (0-9a-z)+$` matches the command followed by a location identifier. Rate limiting is set to allow 10 requests per 30 seconds per channel, with exceeded requests being queued rather than dropped.

### Tell Command

This command matches messages like:

- `!tell alice fizzbuzz`
- Works in all IRC rooms across all networks.

```json
{
  "type": "command.register",
  "commandUUID": "46b21d7a-9c8e-4109-8163-c53946eec809",
  "commandDisplayName": "Tell Message",
  "platform": "^irc$",
  "network": "^.*$",
  "instance": "^.*$",
  "channel": "^.*$",
  "user": "^.*$",
  "regex": "^tell (.*) (.*)$",
  "platformPrefixAllowed": true,
  "nickPrefixAllowed": false,
  "ratelimit": {
    "mode": "drop",
    "level": "user",
    "limit": 10,
    "interval": "10s"
  },
  "ttl": 3600000
}
```

This example demonstrates a platform-specific command that only works on IRC. The regex pattern `^tell (.*) (.*)$` captures two groups: the recipient and the message. Rate limiting is stricter here, allowing only 10 requests per 10 seconds per user, with exceeded requests being dropped rather than queued to prevent abuse.

### Admin Command

This command matches messages like:

- `~admin fizzbuzz`
- Restricted to the `#eevee-admin` channel on the `thegooscloud` network via the `irc` platform from the user `goos@foo.bar.baz` through the connection instance `eevee`.

```json
{
  "type": "command.register",
  "commandUUID": "cf3135fd-2459-45f5-809c-b27683885d9f",
  "commandDisplayName": "Admin Command",
  "platform": "^irc$",
  "network": "^thegooscloud$",
  "instance": "^eevee$",
  "channel": "^eevee-admin$",
  "user": "^goos@foo.bar.baz$",
  "regex": "^~admin .*$",
  "platformPrefixAllowed": false,
  "nickPrefixAllowed": false,
  "ratelimit": false,
  "ttl": 3600000
}
```

This example shows a highly restricted administrative command with exact matching for all criteria.

### General Room Listener

This "command" matches all messages:

- In the `#general` channel of the `thegooscloud` network via the `irc` platform through the connection instance `eevee`.
  
```json
{
  "type": "command.register",
  "commandUUID": "9a8f7b6c-5d4e-3f2g-1h0i-jk9876543210",
  "commandDisplayName": "General Listener",
  "platform": "^irc$",
  "network": "^thegooscloud$",
  "instance": "^eevee$",
  "channel": "^general$",
  "user": "^.*$",
  "regex": "^.*$",
  "platformPrefixAllowed": false,
  "nickPrefixAllowed": false,
  "ratelimit": false,
  "ttl": 3600000
}
```

## Storage

The registry component of the router stores these registrations in memory with automatic cleanup based on TTL. At runtime, it performs lookups based on these registrations to determine which registered commands should receive each incoming message.
