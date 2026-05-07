---
weight: 140
title: "dice"
description: "Virtual dice roller with D&D style dice notation support"
draft: false
---

The Dice module provides virtual dice rolling functionality with support for D&D style dice notation. Users can roll various types of dice with modifiers, exploding dice, and other advanced features.

## Features

- Standard polyhedral dice (d4, d6, d8, d10, d12, d20, etc.)
- Dice modifiers (+/- values)
- Exploding dice
- Keep/drop highest/lowest dice
- Fudge dice (dF)
- ORE-style dice rolling
- Configurable rate limits and throttling
- Support for multiple platforms and networks

## Usage

Send a message beginning with `roll` followed by dice notation to any channel where the bot is present (providing any platform prefix if required):

```none
roll 2d6
```

The bot will respond with the individual dice rolls and total:

```none
rolling 2d6 (3,5) 8
```

### Standard Polyhedral

Roll X dice with Y sides, optionally adding or subtracting a modifier:

```none
roll 2d6        → rolling 2d6 (3,5) 8
roll 1d20+5     → rolling 1d20+5 (17) 22
roll 3d8-2      → rolling 3d8-2 (4,7,2) 11
```

Omitting the die count rolls a single die:

```none
roll d20        → rolling 1d20 (14) 14
```

### Shorthand (Bare Number)

A bare number is shorthand for rolling a single die with that many sides:

```none
roll 20         → rolling 1d20 (14) 14
```

### Exploding Dice

Append `!` to make dice **explode** — when a die rolls its maximum value, roll it again and add the result. This chains as long as the max keeps coming up.

```none
roll 3d6!       → rolling 3d6! (6,2,6,4,3) 21
```

The explosion threshold equals the number of sides on the die. Each exploded die that hits max triggers another reroll, up to the configured `maxDice` limit.

### Keep and Drop

Use keep/drop modifiers to select a subset of the rolled dice:

- **kN** — Keep the highest N dice
- **kdN** — Keep the lowest N dice (equivalently, drop the highest N)

```none
roll 4d6k3      → rolling 4d6k3 (2,5,4,6) 15
roll 2d20k1     → rolling 2d20k1 (8,15) 15    (advantage)
roll 2d20kd1    → rolling 2d20d1 (12,4) 4      (disadvantage)
```

#### Alternate Keep Syntax

You can also use the word `keep` instead of the `k` suffix:

```none
roll 4d6 keep 3 → rolling 4d6k3 (1,6,3,5) 14
```

### Fudge Dice

Fudge dice (`dF`) have three faces: `+`, `o` (zero), and `-`. The result is the numeric sum, where `+` = 1, `o` = 0, and `-` = -1.

```none
roll 4dF        → rolling 4dF (+,o,-,+) 1
```

Fudge dice are commonly used in Fate-based RPGs. A typical roll is `4dF`, producing results from -4 to +4.

### ORE (One-Roll Engine)

Use the `XoreY` notation to roll One-Roll Engine dice. X dice are rolled with Y sides each, and the results are grouped into matching sets displayed as `width×height` (e.g., `3x7` means three dice showing 7).

```none
roll 9ore10     → rolling 9ore10 (3x7,2x4,1x2,1x6,1x9,1x3)
```

The number of dice is capped at the number of sides (rolling more dice than faces can't produce wider sets). ORE is used in games like *Wild Talents* and *Nemesis*.

## Notation Reference

| Notation | Meaning |
|----------|---------|
| `XdY` | Roll X dice with Y sides each |
| `XdY+Z` | Roll and add modifier Z |
| `XdY-Z` | Roll and subtract modifier Z |
| `XdY!` | Exploding dice (reroll on max) |
| `XdYkN` | Keep highest N dice |
| `XdYkdN` | Keep lowest N dice (drop highest) |
| `XdY keep N` | Alternate keep syntax — keep highest N dice |
| `XdF` | Roll X Fudge dice (`+`, `o`, `-`) |
| `XoreY` | Roll X ORE-style dice with Y sides |
| `N` | Shorthand for `1dN` |

## Configuration

The dice module reads its configuration from eevee's shared module config system. No environment variables beyond the standard eevee ones are required.

### Options

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `ratelimit` | `RateLimitConfig` | libeevee default | Rate limiting for the `roll` command |
| `maxDice` | `number` | `64` | Maximum number of dice in a single roll |
| `maxSides` | `number` | `65535` | Maximum number of sides per die |

### Example Configuration

```yaml
botModules:
- name: dice
  spec:
    size: 1
    image: ghcr.io/eeveebot/dice:latest
    pullPolicy: Always
    metrics: true
    metricsPort: 8080
    ipcConfig: my-eevee-bot
    moduleName: dice
    moduleConfig: |
      ratelimit:
        mode: drop
        level: user
        limit: 10
        interval: 1m
      maxDice: 100
      maxSides: 1000
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `HTTP_API_PORT` | `9000` | Port for metrics and health check HTTP server |
