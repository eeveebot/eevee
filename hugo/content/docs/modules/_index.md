---
weight: 400
title: "Modules"
description: "Various modules that make up eevee-bot"
draft: false
---

The eevee.bot framework is composed of various modules that work together to provide
chatbot functionality. Each module serves a specific purpose and can be configured
independently.

## Core Modules

- [router](router/) - Core message router
- [admin](admin/) - Administration and configuration management
- [toolbox](toolbox/) - Utility and monitoring tools

## Chat Connectivity Modules

- [connector-irc](connector-irc/) - IRC connectivity

## Utility Modules

- [calculator](calculator/) - Mathematical expression evaluator
- [cli](cli/) - Command-line interface for eevee management
- [crds](crds/) - Custom Resource Definitions for the eevee ecosystem
- [help](help/) - Help documentation and !help command provider
- [operator](operator/) - Kubernetes operator for managing eevee resources
- [tell](tell/) - Interstellar answering machine for offline messaging
- [urltitle](urltitle/) - Automatic URL title fetching for posted links
- [weather](weather/) - Weather information provider

## Fun Modules

- [dice](dice/) - Virtual dice roller with D&D style dice notation support
- [echo](echo/) - Simple message echoing functionality
- [emote](emote/) - Text-based emote commands
