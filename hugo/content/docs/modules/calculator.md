---
weight: 110
title: "calculator"
description: "Mathematical expression evaluator for eevee.bot"
draft: false
---

The Calculator module provides in-chat mathematical expression evaluation for eevee.bot. When a user issues a `!calc` or `!c` command, the module parses and evaluates the expression using [mathjs](https://mathjs.org/) and returns the result directly in the channel.

## Features

- Mathematical expression evaluation via mathjs (arithmetic, trigonometry, logarithms, constants, and more)
- Two command aliases — `!calc` and `!c` for quick access
- Rate limiting — configurable per-command rate limits to prevent spam
- Error reporting — parse and evaluation errors surfaced inline in chat
- Factorial protection — `!` and `factorial` blocked to prevent resource abuse
- Prometheus metrics, help registration, and stats endpoints

## Usage

Send a message beginning with `calc` or `c` followed by a mathematical expression to any channel where the bot is present (providing any platform prefix if required):

```none
!calc 2 + 2 * 3
```

The bot will respond with:

```none
8
```

The `!c` shorthand works identically:

```none
!c sin(pi/2)
```

```none
1
```

More examples:

```none
!calc sqrt(144)
!c log(100, 10)
!calc 1.5 * 10^6
!calc 5.4 kg to lb
```

### Supported Operations

Calculator delegates to mathjs, supporting the full [mathjs expression syntax](https://mathjs.org/docs/expressions/syntax.html):

- **Arithmetic:** `+`, `-`, `*`, `/`, `^`, `%`, `mod`
- **Trigonometry:** `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, etc.
- **Logarithms:** `log(x)`, `log(x, base)`, `log10`, `log2`
- **Roots & powers:** `sqrt`, `cbrt`, `nthRoot`, `pow`
- **Constants:** `pi`, `e`, `phi`, `Infinity`, `NaN`
- **Rounding:** `round`, `ceil`, `floor`, `fix`
- **Combinatorics:** `combinations`, `permutations` (factorial is disabled)
- **Units:** `5.4 kg to lb`, `2 inch to cm`

### Factorial Protection

Factorial operations are explicitly disabled to prevent abuse. Both the postfix `!` operator and the `factorial()` function are blocked before evaluation:

```none
!calc 5!
Error: Factorials disabled

!calc factorial(5)
Error: Factorials disabled
```

This prevents computing astronomically large numbers that could degrade performance.

## Configuration

To deploy the calculator module, add it to your bot's `botModules` configuration with `moduleName: "calculator"`:

```yaml
botModules:
- name: calculator
  spec:
    size: 1
    image: ghcr.io/eeveebot/calculator:latest
    pullPolicy: Always
    metrics: true
    metricsPort: 8080
    ipcConfig: my-eevee-bot
    moduleName: calculator
    moduleConfig: |
      ratelimit:
        mode: drop
        level: user
        limit: 5
        interval: 1m
```
