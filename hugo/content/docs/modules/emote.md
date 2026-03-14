---
weight: 300
title: "emote"
description: "Text-based emote commands for eevee.bot"
draft: false
---

The Emote module provides various text-based emote commands for eevee.bot. These
commands send predefined text responses or transform input text into stylized formats.

## Features

- Multiple emote commands with different text responses
- Random selection for some emotes (dunno)
- Text transformation capabilities (intense)
- Rate limiting configurable per deployment
- Cross-platform compatibility
- Automatic command registration

## Available Commands

| Command       | Description                        | Parameters |
| ------------- | ---------------------------------- | ---------- |
| `dunno`       | Sends a random "I don't know" face | None       |
| `shrug`       | Sends a shrug face                 | None       |
| `dudeweed`    | Sends a "dude weed lmao" message   | None       |
| `downy`       | Sends a downy face                 | None       |
| `doubledowny` | Sends two downy faces in a row     | None       |
| `tripledowny` | Sends three downy faces in a row   | None       |
| `rainbowdowny`| Sends a rainbow-ized downy face    | None       |
| `id`          | Sends an "illegal drugs" message   | None       |
| `ld`          | Sends a "legal drugs" message      | None       |
| `lv`          | Sends a heart symbol               | None       |
| `intense`     | Intensifies provided text          | `<text>`   |

## Usage

Send any of the available commands to any channel where the bot is present
(providing any platform prefix if required):

```none
!dunno
!shrug
!intense This is a test message
```

The bot will respond with the appropriate emote or transformed text.

Examples of responses:

- `!dunno` → `¯\_(ツ)_/¯` (random selection from 9 different faces)
- `!shrug` → `¯\_(ツ)_/¯`
- `!intense Hello` → `[Hello intensifies]`

## Configuration

To deploy the emote module, add it to your bot's `botModules` configuration with
`moduleName: "emote"`:

```yaml
botModules:
- name: emote
  spec:
    size: 1
    image: ghcr.io/eeveebot/emote:latest
    pullPolicy: Always
    metrics: true
    metricsPort: 8080
    ipcConfig: my-eevee-bot
    moduleName: emote
    moduleConfig: |
      ratelimit:
        mode: drop
        level: user
        limit: 5
        interval: 1m
```

The `ratelimit` configuration controls how frequently users can invoke emote commands:

- `mode`: Either `enqueue` (queue excess requests) or `drop` (discard excess requests)
- `level`: Scope of rate limiting - `channel`, `user`, or `global`
- `limit`: Maximum number of commands per interval
- `interval`: Time period for rate limiting (e.g., `30s`, `1m`, `5m`)
