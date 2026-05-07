---
weight: 410
title: "admin"
description: "Administration and configuration management for eevee.bot"
draft: false
---

The Admin module provides administration and configuration management capabilities for eevee.bot. It handles authentication of administrative users and provides secure access to administrative commands including channel management, module introspection, and operational controls.

## Features

- Authentication of administrative users via IRC hostmask
- Channel management (join/part)
- Rate limit statistics inspection
- Command registry inspection
- Module uptime reporting
- Module restart capability
- Bot module listing via operator API
- Bot statistics aggregation
- Per-command rate limiting

## Commands

All admin commands are prefixed with `admin` and require the user to be authenticated.

| Command | Description |
|---------|-------------|
| `admin join <platform> <network> <instance> <channel>` | Join a channel on a specific platform/network/instance |
| `admin part <platform> <network> <instance> <channel>` | Leave a channel on a specific platform/network/instance |
| `admin show-ratelimits` | Show current rate limit statistics |
| `admin show-command-registry` | Show the current command registry |
| `admin module-uptime` | Show uptime information for all modules |
| `admin module-restart <module>` | Restart a specific module |
| `admin list-bot-modules` | List all bot modules and their deployment information |
| `admin bot-stats` | Show bot statistics from various modules |

## Configuration

The Admin module uses a YAML configuration file to define authorized administrators and rate limits. The configuration file should be mounted to the module container and referenced via the `MODULE_CONFIG_PATH` environment variable.

To deploy the admin module, add it to your bot's `botModules` configuration with `moduleName: "admin"`:

```yaml
botModules:
- name: admin
  spec:
    size: 1
    image: ghcr.io/eeveebot/admin:latest
    pullPolicy: Always
    metrics: true
    metricsPort: 8080
    ipcConfig: my-eevee-bot
    moduleName: admin
    mountOperatorApiToken: true
    moduleConfig: |
      admins:
      - displayName: "root"
        uuid: "123e4567-e89b-12d3-a456-426614174000"
        acceptedPlatforms:
        - "irc"
        - "discord"
        authentication:
          irc:
            hostmask: "root@localhost"
      ratelimits:
        join:
          mode: drop
          level: user
          limit: 3
          interval: 1m
        part:
          mode: drop
          level: user
          limit: 3
          interval: 1m
        showRatelimits:
          mode: drop
          level: user
          limit: 3
          interval: 1m
        moduleUptime:
          mode: drop
          level: user
          limit: 3
          interval: 1m
        moduleRestart:
          mode: drop
          level: user
          limit: 3
          interval: 1m
        showCommandRegistry:
          mode: drop
          level: user
          limit: 3
          interval: 1m
        listBotModules:
          mode: drop
          level: user
          limit: 3
          interval: 1m
        botStats:
          mode: drop
          level: user
          limit: 3
          interval: 1m
```

## Authentication Methods

Currently, the Admin module supports IRC hostmask authentication. Additional authentication methods may be added in future versions.
