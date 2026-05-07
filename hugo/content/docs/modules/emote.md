---
weight: 300
title: "emote"
description: "Text-based emote commands for eevee.bot"
draft: false
---

The Emote module provides a collection of text-based emote commands for eevee.bot.
When a user triggers a command in a chat channel, emote responds with an ASCII/Unicode
emoticon, a random selection from a face pool, or a transformed version of the user's
input.

Emote is platform-agnostic — commands are registered with `platform: '.*'` so they work
on any connector (IRC, Discord, etc.). On IRC, most emote output is automatically
colorized using `randomColorForPlatform` from `@eeveebot/libeevee`.

## Features

- **11 emote commands** — shrug, dunno, downy (and variants), dudeweed, id, ld, lv, intense
- **Random face selection** — `dunno` and `shrug` pick from curated face pools for variety
- **Multi-line emotes** — `doubledowny` and `tripledowny` send the downy face 2 or 3 times
- **Text transformation** — `intense` wraps user-supplied text in `[... intensifies]` format
- **Random responses** — `id` and `ld` include rare alternate outputs
- **IRC colorization** — output is colorized on IRC platforms via libeevee utilities
- **Rate limiting** — all commands respect the configured rate limit

## Available Commands

| Command           | Output                          | Parameters | Notes |
|-------------------|---------------------------------|------------|-------|
| `dunno`           | Random "I don't know" face      | None       | Picks from 9 faces |
| `shrug`           | Random shrug face               | None       | Picks from 20 faces; classic `¯\_(ツ)_/¯` is weighted |
| `downy`           | `.'​/)`                         | None       | Single downy face |
| `doubledowny`     | `.'​/)` × 2                     | None       | Downy face sent twice |
| `tripledowny`     | `.'​/)` × 3                     | None       | Downy face sent three times |
| `rainbowdowny`    | `.'​/)`                         | None       | Downy face with IRC colorization |
| `dudeweed`        | `dude weed lmao`                | None       | Classic meme |
| `id`              | `illegal drugs`                 | None       | ~20% chance of a rare "dbladez" variant |
| `ld`              | `legal drugs`                   | None       | ~7% chance of an alternate message |
| `lv`              | `♥`                             | None       | A single heart |
| `intense`         | `[<text> intensifies]`          | `<text>`   | Wraps user text in intensify brackets |

## Usage

Send any of the available commands to any channel where the bot is present
(providing the platform's command prefix if required):

```none
!dunno
!shrug
!intense This is a test message
```

The bot will respond with the appropriate emote or transformed text.

### Examples

```none
<user> !dunno
<eevee> 乁໒( ͒ ⌂ ͒ )७ㄏ

<user> !shrug
<eevee> ¯\_(ツ)_/¯

<user> !downy
<eevee> .'/)

<user> !doubledowny
<eevee> .'/)
<eevee> .'/)

<user> !dudeweed
<eevee> dude weed lmao

<user> !id
<eevee> illegal drugs

<user> !ld
<eevee> legal drugs

<user> !lv
<eevee> ♥

<user> !intense javascript
<eevee> [javascript intensifies]
```

## Special Behaviors

### Random Face Pools

- **`dunno`** — Each invocation selects a random face from a pool of 9, including
  `‾\(ツ)/‾`, `¯\(º_o)/¯`, `ʕ ᵒ̌ ‸ ᵒ̌ ʔ`, and more.
- **`shrug`** — Picks from a pool of 20 faces. The classic `¯\_(ツ)_/¯` appears
  most frequently (weighted — appears 4 times in the 20-entry array).

### Rare Alternate Responses

- **`id`** — Has a ~20% chance of selecting from 5 humorous "dbladez" variants
  instead of the default `illegal drugs`.
- **`ld`** — Has a ~7% chance of outputting one of three alternate messages:
  `"There are no legal drugs."`, `"All drugs are illegal."`, or
  `"Your drug use has been logged and reported."`

### IRC Colorization

Most emote commands apply IRC colorization to their output when the originating
platform is IRC. This is handled by `randomColorForPlatform` from `@eeveebot/libeevee`,
which wraps the text in IRC color codes using a randomly selected color.

**Exceptions:**

- **`intense`** — Does not apply IRC colorization.
- **`rainbowdowny`** — Always applies colorization on IRC (this is its distinguishing
  feature from plain `downy`).

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

### Rate Limiting

The `ratelimit` configuration controls how frequently users can invoke emote commands:

| Key        | Type     | Description                                                        |
|------------|----------|--------------------------------------------------------------------|
| `mode`     | string   | `enqueue` (queue excess requests) or `drop` (discard them)        |
| `level`    | string   | Scope of rate limiting — `channel`, `user`, or `global`           |
| `limit`    | number   | Maximum number of commands per interval                            |
| `interval` | string   | Time period for rate limiting (e.g. `30s`, `1m`, `5m`)            |

### Environment Variables

| Variable        | Default | Description                                   |
|-----------------|---------|-----------------------------------------------|
| `HTTP_API_PORT` | `9000`  | Port for the HTTP metrics and health-check server |

## Architecture

Emote communicates entirely through NATS — it never talks to chat platforms directly.

1. At startup, `registerAllCommands()` publishes a `command.register` message to the
   router for each of the 11 commands, each with a unique UUID and the configured rate
   limit.
2. `setupCommandHandlers()` subscribes to `command.execute.<uuid>` for each registered
   command.
3. When the router matches a chat message to a command regex, it publishes to the
   corresponding `command.execute.<uuid>` topic.
4. The handler selects or builds the emote text, optionally colorizes it for IRC, and
   calls `sendChatMessage()` to publish a response back through NATS.
5. The appropriate chat connector picks up the response and sends it to the channel.

### Source Structure

```text
src/
├── main.mts              # Entry point — NATS connection, command registration, subscriptions
├── commandRegistry.mts   # Registers all commands with router, sets up execution handlers
├── commands/
│   ├── dunno.mts         # Random "I don't know" face
│   ├── shrug.mts         # Random shrug face
│   ├── downy.mts         # Single downy emote
│   ├── doubledowny.mts   # Downy × 2
│   ├── tripledowny.mts   # Downy × 3
│   ├── rainbowdowny.mts  # Downy with color
│   ├── dudeweed.mts      # "dude weed lmao"
│   ├── id.mts            # "illegal drugs" with rare variants
│   ├── ld.mts            # "legal drugs" with rare variants
│   ├── lv.mts            # Heart emote
│   └── intense.mts       # [<text> intensifies]
└── utils/
    └── colorize.mts      # IRC colorization wrapper
```
