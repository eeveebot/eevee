---
weight: 200
title: "connector-irc"
description: "IRC connectivity for eevee.bot"
draft: false
---

# IRC Connector Module

The IRC Connector module provides IRC connectivity for eevee.bot. It connects to IRC servers, joins channels, and bridges messages between IRC and the eevee.bot messaging system.

## Features

- Multiple IRC network connections
- Automatic reconnection and rejoin
- Channel management (join/part)
- Message bridging between IRC and eevee.bot
- Configurable ident settings
- SSL/TLS support
- Ping timeout handling

## Configuration

The IRC Connector uses a YAML configuration file specified by the `IRC_CONNECTIONS_CONFIG_FILE` environment variable.

Example configuration:

```yaml
---
:
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
