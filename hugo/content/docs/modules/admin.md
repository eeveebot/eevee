---
weight: 410
title: "admin"
description: "Administration and configuration management for eevee.bot"
draft: false
---

The Admin module manages bot administrators and permissions. It loads administrator configurations from a YAML file and provides administrative commands for controlling chat connectors and inspecting bot state. Administrators are authenticated based on their platform-specific identifiers — currently IRC hostmask matching (both exact and regex) — and only properly authenticated administrators can execute control commands.

## Features

- Administrator authentication via IRC hostmask matching (exact and regex patterns)
- Dynamic channel joining and parting across platforms
- Rate-limit statistics inspection (`admin show-ratelimits`)
- Command registry inspection (`admin show-command-registry`)
- Module uptime reporting (`admin module-uptime`)
- Module restart capability (`admin module-restart`)
- Bot module listing with deployment info (`admin list-bot-modules`)
- Bot statistics aggregation (`admin bot-stats`)
- Per-command configurable rate limiting
- NATS messaging integration for command routing and inter-service communication
- Prometheus metrics and health-check HTTP endpoint

## Commands

All admin commands are prefixed with `admin` and require the user to be authenticated.

| Command | Description |
|---------|-------------|
| `admin join <platform> <network> <instance> <channel>` | Join a channel on a specific platform/network/instance |
| `admin part <platform> <network> <instance> <channel>` | Leave a channel on a specific platform/network/instance |
| `admin show-ratelimits` | Show current rate limit statistics from the router |
| `admin show-command-registry` | Show the current command registry from the router |
| `admin module-uptime` | Show uptime information for all active bot modules |
| `admin module-restart <module>` | Restart a specific module |
| `admin list-bot-modules` | List all bot modules and their deployment information |
| `admin bot-stats` | Show aggregated statistics from various bot modules |

## Authentication

Administrators are authenticated based on their platform-specific identifiers:

- **IRC**: Hostmask matching — supports both exact matches and regex patterns. The module constructs a full hostmask in the format `user@host` and checks it against each admin's configured hostmask. If the regex is invalid, it falls back to exact string comparison.
- Currently, only IRC authentication is supported; other platforms are rejected.

Only properly authenticated administrators can execute control commands. All command attempts are logged for security auditing.

### Auth Configuration Format

Each admin entry in the config includes:

| Field | Required | Description |
|-------|----------|-------------|
| `displayName` | Yes | Human-readable name for the administrator |
| `uuid` | Yes | Unique identifier for this admin entry |
| `acceptedPlatforms` | Yes | Array of platform identifiers or regex patterns this admin can operate on |
| `authentication.irc.hostmask` | Yes | IRC hostmask pattern for identification (supports regex) |

## Operator API Token

The admin module requires the `mountOperatorApiToken` field to be set to `true` in the botmodule spec. This mounts the Kubernetes operator API token, which the module uses to communicate with the eevee operator for tasks such as listing deployed modules and triggering restarts.

## NATS Subjects

| Subject | Direction | Purpose |
|---------|-----------|---------|
| `command.register` | Outbound | Registers each admin command with the router |
| `command.execute.<UUID>` | Inbound | Receives routed command invocations |
| `help.update` | Outbound | Publishes admin help docs |
| `help.updateRequest` | Inbound | Responds to help refresh requests |
| `control.registerCommands.*` | Inbound | Re-registers commands on demand |
| `stats.emit.request` | Inbound | Responds with uptime, memory, and Prometheus metrics |

## Configuration

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
