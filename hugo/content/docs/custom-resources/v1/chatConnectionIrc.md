---
weight: 512
title: "eevee.bot/v1/chatConnectionIrc"
description: ""
draft: false
---

## `eevee.bot/v1/chatConnectionIrc`

This file defines a Custom Resourceexample for an IRC chat connection in the eevee.bot/v1 API. It shows how to configure a bot named "my-eevee-bot" to connect to an IRC network "my-irc-network" with settings such as:

- Server details (host, port, SSL)
- Reconnection and rejoin behaviors
- Bot identity (nick, username, real name)
- Admin users and permissions
- Environment variables (like NickServ authentication tokens)
- Post-connect actions (authenticating with NickServ, joining channels, sending messages)
- Command handling configuration

The example demonstrates advanced features like referencing secrets for sensitive data (passwords, keys) and defining multiple post-connect actions.
It also enables broadcasting of all received messages and sets up command processing with a common prefix regex.

```yaml
---
apiVersion: eevee.bot/v1
kind: chatConnectionIrc
metadata:
  name: my-eevee-bot
  namespace: my-eevee-bot
spec:
  ipcConfig: my-eevee-bot
  # Connection list
  connections:
  # Display name for this network
  - name: my-irc-network
    # Enable this connection
    enabled: true
    # Define IRC connection parameters
    irc:
      # Host to connect to
      host: irc.my-irc-network.local
      # Port
      port: 6667
      # SSL
      ssl: true
      # Other params
      autoReconnect: true
      autoReconnectWait: 5000
      autoReconnectMaxRetries: 10
      autoRejoin: true
      autoRejoinWait: 5000
      autoRejoinMaxRetries: 5
      pingInterval: 30
      pingTimeout: 120
    # IRC Ident info
    ident:
      # Nick to use on this network
      nick: eevee
      username: eevee
      gecos: eevee.bot
      # These default to the actual bot version if not defined
      version: "0.4.20"
      quitMsg: "eevee v0.4.20"
    # Statically defined bot admins
    # TODO: admins in database
    rbac:
      users:
        its-you:
          auth: ident
          ident: your@ident.hostmask
          groups:
          - root
    # Actions to take after connecting to the server
    postConnect:
    # Send a PM when we connect to the server
    # You can have the text of the message stored as a secret
    - action: msg
      channel: 'nickserv' # irc-ism: no # means this is for a user (the nickserv bot in this case)
      secretKeyRef:
        secret:
          name: my-irc-network-secrets
        key: nickserv-ident-message # "identify MYTOKEN"
    # Join some channels
    - action: join
      channels:
      # Open channel
       - channel: '#bots'
      # Channel that requires a key
      - channel: '#cool-kids-club'
        secretKeyRef:
          secret:
            name: my-irc-network-secrets
          key: channel-key-cool-kids-club
    # You can also specify msg content as a string here
    - action: msg
      channel: '#bots' # irc-ism: the # means this is for a channel
      msg: hello world
    # Send broadcast events for all received messages
    broadcastMessages: true
    # Settings related to command modules
    commands:
      # Common prefix regex to add to registered command regexes
      commonPrefixRegex: "^-"
```
