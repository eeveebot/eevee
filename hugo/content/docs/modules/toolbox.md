---
weight: 150
title: "toolbox"
description: "Utility and monitoring tools for eevee.bot"
draft: false
---

The Toolbox module provides utility and monitoring functionality for eevee.bot. It runs the `eevee-monitor` command which subscribes to all NATS subjects and displays incoming messages, making it useful for debugging and monitoring the bot's message flow.

## Features

- Real-time message monitoring
- NATS subject subscription visualization
- Debugging and troubleshooting capabilities
- Cross-platform message inspection

## Usage

The toolbox module doesn't require any specific commands to be interacted with. Instead, it passively monitors all messages flowing through the eevee.bot messaging system and logs them to stdout.

When deployed, you can view the toolbox output using:

```bash
kubectl logs -n <namespace> deployment/<bot-name>-toolbox-module
```

## Configuration

To deploy the toolbox module, add it to your bot's `botModules` configuration with `moduleName: "toolbox"`:

```yaml
botModules:
- name: toolbox
  spec:
    size: 1
    image: ghcr.io/eeveebot/cli:latest
    pullPolicy: Always
    metrics: true
    metricsPort: 8080
    ipcConfig: my-eevee-bot
    moduleName: toolbox
```

## Monitoring Output

The toolbox will display messages in the following format:

```none
[subject.name] {"message": "content"}
```

Where `subject.name` is the NATS subject the message was sent on, and the JSON content is the message payload.
