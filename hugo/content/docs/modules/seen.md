---
weight: 175
title: "seen"
description: "Track when users were last seen in channels"
draft: false
---

The Seen module tracks when users were last seen in channels, allowing other users to check when someone was last active. It also provides a `since` command to see who has been active in a specified time period.

## Features

- Track user activity across channels
- Check when a user was last seen with `seen <username>`
- See who has been active recently with `since <minutes>`
- Persistent storage using SQLite database
- Rate limiting to prevent abuse
- Multi-platform support

## Usage

### Check When Someone Was Last Seen

To check when a user was last seen:

```none
seen <username>
```

Example:

```none
seen alice
```

The bot will respond with information about when and where the user was last seen.

### Check Who Has Been Active Recently

To see who has been active in the last X minutes (up to 1440 minutes/24 hours):

```none
since <minutes>
```

Example:

```none
since 30
```

The bot will respond with a list of users who have been active in the last 30 minutes.

## Configuration

To deploy the seen module, add it to your bot's `botModules` configuration with `moduleName: "seen"`:

```yaml
botModules:
- name: seen
  spec:
    size: 1
    image: ghcr.io/eeveebot/seen:latest
    pullPolicy: Always
    metrics: true
    metricsPort: 8080
    ipcConfig: my-eevee-bot
    moduleName: seen
    moduleConfig: |
      ratelimit:
        mode: drop
        level: user
        limit: 5
        interval: 1m
```

## Requirements

This module requires Node.js to be installed for building the native modules.