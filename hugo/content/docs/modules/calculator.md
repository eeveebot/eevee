---
weight: 110
title: "calculator"
description: "Mathematical expression evaluator for eevee.bot"
draft: false
---

The Calculator module provides mathematical expression evaluation functionality for eevee.bot. It listens for messages beginning with "calc " or "c " and evaluates the provided mathematical expression using mathjs.

## Features

- Mathematical expression evaluation using mathjs
- Support for complex mathematical operations
- Rate limiting (5 evaluations per minute per user by default)
- Cross-platform compatibility
- Automatic command registration
- Factorial operations disabled for security reasons

## Usage

Send a message beginning with `calc` or `c` followed by a mathematical expression to any channel where the bot is present (providing any platform prefix if required):

```none
!calc 2 + 2 * 3
```

The bot will respond with:
```none
8
```

More complex examples:
```none
!calc sqrt(16) + pow(2, 3)
!c sin(pi/2)
!calc 100 / (2 * 5)
```

## Security

Factorial operations (!) are disabled in this module to prevent potential abuse that could cause performance issues.

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