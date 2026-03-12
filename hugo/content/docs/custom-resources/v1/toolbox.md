---
weight: 512
title: "toolbox"
description: "eevee.bot/v1/toolbox"
draft: false
---

## `eevee.bot/v1/toolbox`

This file defines a Custom Resource example for the toolbox configuration in the eevee.bot/v1 API. It shows how to configure a bot named "my-eevee-bot" with settings such as:

- Size (number of replicas) for the toolbox deployment
- Image specification with registry and tag
- Image pull policy for updating the container image
- Metrics enable/disable flag
- IPC configuration name

The example demonstrates the basic configuration needed to deploy the eevee toolbox component which provides utility functions and tools for the bot ecosystem.

```yaml
---
apiVersion: eevee.bot/v1
kind: toolbox
metadata:
  name: my-eevee-bot
  namespace: my-eevee-bot
spec:
  size: 1
  image: ghcr.io/eeveebot/cli:latest
  pullPolicy: Always
  metrics: false
  ipcConfig: my-eevee-bot
```
