---
weight: 150
title: "help"
description: "Help documentation and !help command provider"
draft: false
---

The Help module manages help documentation and provides the !help and !bots commands for eevee.bot. It aggregates help information from all modules and presents it to users.

## Features

- Centralized help documentation management
- !help command for accessing module-specific help
- !bots command for listing available bots
- Dynamic help updates from modules
- Cross-platform compatibility

## Usage

Users can access help information by sending the following commands in any channel where the bot is present:

```
!help
```

This will display a list of available commands and modules.

```
!help <module>
```

This will display detailed help information for a specific module.

```
!bots
```

This will display information about available bots in the system.

## Configuration

To deploy the help module, add it to your bot's `botModules` configuration with `moduleName: "help"`:

```yaml
botModules:
- name: help
  spec:
    size: 1
    image: ghcr.io/eeveebot/help:latest
    pullPolicy: Always
    metrics: true
    metricsPort: 8080
    ipcConfig: my-eevee-bot
    moduleName: help
```