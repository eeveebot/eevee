---
weight: 100
title: "echo"
description: "Simple message echoing functionality for eevee.bot"
draft: false
---

The Echo module provides simple message echoing functionality for eevee.bot. It listens for messages beginning with "echo " and responds by sending the same message back to the originating channel.

## Features

- Message echoing functionality
- Rate limiting (5 messages per minute per user)
- Cross-platform compatibility
- Automatic command registration

## Usage

Send a message beginning with `echo` to any channel where the bot is present (providing any platform prefix if required):

```none
!echo Hello, world!
```

The bot will respond with:

```none
Hello, world!
```

## Configuration

To deploy the echo module, add it to your bot's `botModules` configuration with `moduleName: "echo"`:

```yaml
botModules:
- name: echo
  spec:
    size: 1
    image: ghcr.io/eeveebot/echo:latest
    pullPolicy: Always
    metrics: true
    metricsPort: 8080
    ipcConfig: my-eevee-bot
    moduleName: echo
    moduleConfig: |
      # Echo module configuration (currently empty)
```
