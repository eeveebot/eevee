---
weight: 410
title: "admin"
description: "Administration and configuration management for eevee.bot"
draft: false
---

The Admin module provides administration and configuration management capabilities
for eevee.bot. It handles authentication of administrative users and provides secure
access to administrative commands and functions.

## Features

- Authentication of administrative users
- Platform-specific admin validation
- Secure access to administrative commands
- Configuration management for admin permissions

## Configuration

The Admin module uses a YAML configuration file to define authorized administrators.
The configuration file should be mounted to the module container and referenced
via the `MODULE_CONFIG_PATH` environment variable.

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
      ratelimit:
        mode: drop
        level: user
        limit: 5
        interval: 1m
```

## Authentication Methods

Currently, the Admin module supports IRC hostmask authentication. Additional authentication
methods may be added in future versions.
