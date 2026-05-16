---
weight: 100
title: "superslap"
description: "Various slap commands targeting users in a channel"
draft: false
---

The Superslap module provides a family of slap commands with escalating intensity. When a user invokes a command, the bot selects a random vulnerable user from the channel, stages a dramatic multi-line animation over several seconds, and — depending on the variant — kicks the target from the channel.

## Features

- Multiple slap variants with different intensities and animations
- Random target selection from channel users with vulnerability filtering
- Configurable invulnerability lists (by nick and hostmask pattern)
- IRC operator mode protection (`+o`, `+O`, `+a`, `+q`) — operators are never targeted
- Delayed message sequences for dramatic animation (1s → 3s → 6s → 8s → 10s → 12s)
- Multi-language variants (English, Spanish, Japanese)
- Per-command rate limiting
- Automatic command and help registration via libeevee

## Commands

| Command | Description |
|---------|-------------|
| `slapanus` | Casual slap — stages a brief animation, no kick |
| `superslapanus` | Super slap — dramatic animation + kick |
| `superslapanusv2` | Super slap v2 — rainbow-coloured animation + kick. Invulnerable users get a snarky reply instead |
| `superslapaniggasanus` | Super slap variant — its own flavour of chaos + kick |
| `supersuckurdick` | Mystery variant — its own flavour of chaos + kick |
| `superslapsiesta` | Spanish-language super slap + kick. Random kick message drawn from a pool |
| `superslapbaka` | Japanese-language super slap + kick |

## Usage

Send any of the slap commands to the channel where the bot is present:

```none
!superslapanus
```

```none
<bot> IT'S SUPER ANUS SLAPPING TIME!
<bot> fishy spits onto the floor!
<bot> The saliva reads...
<bot> victim!
* bot slaps victim's anus!!
*** victim was kicked by bot (SUPERANALSUPERANAL…)
```

If the caller is on the invulnerable list or has operator modes, the "super" variants respond with a dismissal instead of running the full animation.

## Invulnerability Filtering

Users are never targeted if they meet any of these criteria:

- Their nick appears in the `invulnerableUsers.users` config list
- Their hostmask matches a pattern in the `invulnerableUsers.hostmasks` config list (regex, falls back to exact match on invalid regex)
- They hold an IRC operator mode (`+o`, `+O`, `+a`, `+q`)

The bot itself and the command sender are also excluded from target selection.

## Delayed Sequences

Slap animations are staged as timed sequences of `say`, `action`, and `raw` (kick) messages with increasing delays for dramatic effect. The standard timing pattern is:

1s → 3s → 6s → 8s → 10s → 12s

This creates a buildup effect where the audience sees the escalation before the final kick lands.

## Configuration

To deploy the superslap module, add it to your bot's `botModules` configuration with `moduleName: "superslap"`:

```yaml
botModules:
- name: superslap
  spec:
    size: 1
    image: ghcr.io/eeveebot/superslap:latest
    pullPolicy: Always
    metrics: true
    metricsPort: 8080
    ipcConfig: my-eevee-bot
    moduleName: superslap
    moduleConfig: |
      invulnerableUsers:
        users:
        - admin
        - moderator
        hostmasks:
        - "trusted.*"
      ratelimits:
        slapanus: { mode: drop, level: user, limit: 5, interval: 1m }
        superslapanus: { mode: drop, level: user, limit: 5, interval: 1m }
        superslapaniggasanus: { mode: drop, level: user, limit: 5, interval: 1m }
```

### Configuration Keys

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `invulnerableUsers.users` | `string[]` | `["admin", "moderator"]` | Nicks that can never be targeted |
| `invulnerableUsers.hostmasks` | `string[]` | `[]` | Hostmask regex patterns; matching users are immune. Falls back to exact match if the regex is invalid |
| `ratelimits.<command>` | `RateLimitConfig` | libeevee default | Per-command rate limit. Keys match command display names (e.g. `slapanus`, `superslapbaka`) |
