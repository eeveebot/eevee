---
weight: 170
title: "tell"
description: "Interstellar answering machine for offline messaging"
draft: false
---

The Tell module is an interstellar answering machine that allows users to leave messages for other users who may not be online at the moment. When the recipient joins a channel or sends a message, they will receive all pending messages that were left for them.

## Features

- Leave messages for offline users with `tell <username> <message>`
- Delete your own messages with `rmtell <message-id>`
- Automatic delivery of pending messages when users are active
- Persistent storage using SQLite database
- Rate limiting to prevent abuse
- Multi-platform support

## Usage

### tell Someone Something

To leave a message for someone who is not currently online:

```none
tell <username> <message>
```

Example:

```none
tell alice Hey, check out this cool link!
```

### Removing Your Messages

To remove a message you previously sent:

```none
rmtell <message-id>
```

Example:

```none
rmtell a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

The message ID is provided when your message is stored for delivery to the recipient.

## Configuration

To deploy the tell module, add it to your bot's `botModules` configuration with `moduleName: "tell"`:

```yaml
botModules:
- name: tell
  spec:
    size: 1
    image: ghcr.io/eeveebot/tell:latest
    pullPolicy: Always
    metrics: true
    metricsPort: 8080
    ipcConfig: my-eevee-bot
    moduleName: tell
    moduleConfig: |
      ratelimit:
        mode: drop
        level: user
        limit: 5
        interval: 1m
```

## Requirements

This module requires Python 3.x to be installed for building the `better-sqlite3` native module.
