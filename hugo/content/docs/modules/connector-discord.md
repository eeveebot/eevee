---
weight: 201
title: "connector-discord"
description: "Discord connectivity for eevee.bot"
draft: false
---

The Discord Connector module provides Discord connectivity for eevee.bot using the botmodule CRD. It connects to Discord servers, joins channels, and bridges messages between Discord and the eevee.bot messaging system.

The Discord bot token is loaded from the `DISCORD_BOT_TOKEN` environment variable, which is provided by the eevee.bot operator from a Kubernetes secret.

## Features

- Discord bot integration
- Multiple guild connections
- Automatic reconnection
- Channel management (join/leave)
- Message bridging between Discord and eevee.bot
- Role-based permissions
- Rich presence support
- Secure bot token handling via Kubernetes secrets

## Configuration

The Discord Connector is deployed as a botmodule with `moduleName: "discord"`. The Discord configuration is specified in the `moduleConfig` field.

### Bot Token Configuration

The Discord bot token is loaded from the `DISCORD_BOT_TOKEN` environment variable. The eevee.bot operator provides this environment variable to the connector module by injecting a Kubernetes secret specified in the `envSecret` field of the botmodule CRD.

First, create a Kubernetes secret containing your Discord bot token:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: discord-bot-token-secret
type: Opaque
data:
  DISCORD_BOT_TOKEN: <base64-encoded-bot-token>
```

Then reference this secret in your botmodule configuration using the `envSecret` field:

### Example Configuration

```yaml
botModules:
- name: discord-connector
  spec:
    size: 1
    image: ghcr.io/eeveebot/connector-discord:latest
    pullPolicy: Always
    metrics: true
    metricsPort: 8080
    ipcConfig: my-eevee-bot
    moduleName: discord
    envSecret:
      name: discord-bot-token-secret
    moduleConfig: |
      connections:
      - name: my-discord-server
        enabled: true
        discord:
          autoReconnect: true
          autoReconnectWait: 5000
          autoReconnectMaxRetries: 10
        postConnect:
          - action: join
            join:
              - channel: 'general'
              - channel: 'bots'
        commands:
          commonPrefixRegex: "^-"
```
