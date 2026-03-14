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

Send a message beginning with `.roll` followed by dice notation to any channel where the bot is present:

```none
.roll 2d6
```

The bot will respond with the individual dice rolls and total:
```none
2d6 ⇒ 3, 5 ⇒ 8
```

### Dice Notation

- **XdY** - Roll X dice with Y sides
- **+Z/-Z** - Modifier to add/subtract from total
- **!** - Exploding dice (reroll max values)
- **kN** - Keep highest N dice
- **kdN** - Keep lowest N dice (drop highest)

### Examples

```