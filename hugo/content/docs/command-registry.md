---
weight: 999
title: "Command Registry"
description: ""
icon: "article"
date: "2025-08-24T07:58:56-04:00"
lastmod: "2025-08-24T07:58:56-04:00"
draft: false
toc: true
menus:
  main:
    parent: Spec
---

Modules register commands they want to handle messages for as follows:

## Example Command Registrations

### Weather Command

This command matches messages like:

- `!weather 12345`
- Works across all platforms, networks, instances, and channels.
  
```json
{
  "type": "command.register",
  "commandUUID": "d462389d-a4f5-4d38-b738-3fa2ae89c2ad",
  "platform": "^.*$",
  "network": "^.*$",
  "instance": "^.*$",
  "channel": "^.*$",
  "user": "^.*$",
  "regex": "^weather (0-9a-z)+$",
  "platformPrefixAllowed": true,
  "ratelimit": {
    "mode": "enqueue",
    "level": "channel",
    "limit": 10,
    "interval": "30s"
  }
}
```

### Tell Command

This command matches messages like:

- `!tell alice fizzbuzz`
- Works in all IRC rooms across all networks.
  
```json
{
  "type": "command.register",
  "commandUUID": "46b21d7a-9c8e-4109-8163-c53946eec809",
  "platform": "^irc$",
  "network": "^.*$",
  "instance": "^.*$",
  "channel": "^.*$",
  "user": "^.*$",
  "regex": "^tell (.*) (.*)$",
  "platformPrefixAllowed": true,
  "ratelimit": {
    "mode": "drop",
    "level": "user",
    "limit": 10,
    "interval": "10s"
  }
}
```

### Admin Command

This command matches messages like:

- `~admin fizzbuzz`
- Restricted to the `#eevee-admin` channel on the `thegooscloud` network via the `irc` platform from the user `goos@foo.bar.baz` through the connection instance `eevee`.
  
```json
{
  "type": "command.register",
  "commandUUID": "cf3135fd-2459-45f5-809c-b27683885d9f",
  "platform": "^irc$",
  "network": "^thegooscloud$",
  "instance": "^eevee$",
  "channel": "^eevee-admin$",
  "user": "^goos@foo.bar.baz$",
  "regex": "^~admin .*$",
  "platformPrefixAllowed": false,
  "ratelimit": false
}
```

### General Room Listener

This "command" matches all messages:

- In the `#general` channel of the `thegooscloud` network via the `irc` platform through the connection instance `eevee`.
  
```json
{
  "type": "command.register",
  "commandUUID": "9a8f7b6c-5d4e-3f2g-1h0i-jk9876543210",
  "platform": "^irc$",
  "network": "^thegooscloud$",
  "instance": "^eevee$",
  "channel": "^general$",
  "user": "^.*$",
  "regex": "^.*$",
  "platformPrefixAllowed": false,
  "ratelimit": false
}
```

## Storage

The registry component of the router stores these registrations in Nats. At runtime, it performs lookups based on these registrations.
