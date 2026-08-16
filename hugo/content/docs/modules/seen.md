---
weight: 175
title: "seen"
description: "Track when users were last seen in channels"
draft: false
---

The Seen module tracks when users were last seen in channels, allowing other users to check when someone was last active. It also provides a `since` command to see who has been active in a specified time period, a `lurkers` command to list inactive users, and a `lastwords` command to recall what someone said right before leaving a channel.

## Features

- Track user activity across channels
- Check when a user was last seen with `seen <username>`
- See who has been active recently with `since <minutes>`
- List inactive users with `lurkers`
- Generate detailed lurkers reports with `lurkers-report` (channel-admin only)
- Recall last words before departure with `lastwords <username>`
- Persistent storage using SQLite database
- Rate limiting to prevent abuse
- Multi-platform support
- IRC colorized output

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

### List Inactive Users (Lurkers)

To see who has not been active recently:

```none
lurkers [days] [--limit N]
```

The bot will respond with a list of users who have not been seen recently in the channel.

- `days` — number of days to look back (default: 30, max: 365)
- `--limit N` / `-l N` — maximum number of lurkers to display (default: 10, max: 50)

### Generate a Lurkers Report

To generate a comprehensive lurkers report sent via private message:

```none
lurkers-report [days]
```

This command is restricted to channel admins (users with `+o`, `+O`, `+a`, or `+q` modes). It produces a detailed breakdown of active, inactive, and never-seen users in the channel, delivered via PM.

- `days` — number of days for the activity window (default: 30, max: 365)

### Check Last Words Before Departure

To see what a user last said before leaving a channel (part, quit, or kick):

```none
lastwords <username>
```

Example:

```none
lastwords alice
```

The bot will respond with the user's last message, the departure type, which channel they left, when, and the reason (if any). The lookup searches across all channels — not just the one where the command is issued.

Only users who have spoken at least once are tracked. Lurkers who never sent a message are not recorded.

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

This module uses `better-sqlite3` for persistent storage, which requires native compilation during `npm install`. Ensure your build environment has a C++ compiler and Python 3 (for `node-gyp`). Node.js ≥24 is required.