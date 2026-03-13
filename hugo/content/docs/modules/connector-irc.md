---
weight: 200
title: "connector-irc"
description: "IRC connectivity for eevee.bot"
draft: false
---

The IRC Connector module provides IRC connectivity for eevee.bot using the botmodule CRD. It connects to IRC servers, joins channels, and bridges messages between IRC and the eevee.bot messaging system.

## Features

- Multiple IRC network connections
- Automatic reconnection and rejoin
- Channel management (join/part)
- Message bridging between IRC and eevee.bot
- Configurable ident settings
- SSL/TLS support
- Ping timeout handling

## Configuration

The IRC Connector is deployed as a botmodule with `moduleName: "irc"`. The IRC configuration is specified in the `moduleConfig` field.

Example configuration:

```yaml
botModules:
- name: irc-connector
  spec:
    size: 1
    image: ghcr.io/eeveebot/connector-irc:latest
    pullPolicy: Always
    metrics: true
    metricsPort: 8080
    ipcConfig: my-eevee-bot
    moduleName: irc
    moduleConfig:
      connections:
      - name: my-irc-network
        enabled: true
        irc:
          host: irc.my-irc-network.local
          port: 6667
          ssl: true
          autoReconnect: true
          autoReconnectWait: 5000
          autoReconnectMaxRetries: 10
          autoRejoin: true
          autoRejoinWait: 5000
          autoRejoinMaxRetries: 5
          pingInterval: 30
          pingTimeout: 120
        ident:
          nick: eevee
          username: eevee
          gecos: eevee.bot
          version: "0.4.20"
          quitMsg: "eevee v0.4.20"
        postConnect:
          - action: join
            join:
              - channel: '#bots'
              - channel: '#cool-kids-club'
        commands:
          commonPrefixRegex: "^-"
```
