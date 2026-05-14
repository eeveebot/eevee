---
weight: 150
title: "help"
description: "Help documentation and !help command provider"
draft: false
---

The Help module is the central documentation hub for eevee.bot. It collects help registrations from other modules at runtime, stores them in an in-memory registry, and serves them to users via the `!help` and `!bots` chat commands. When the module starts, it broadcasts a `help.updateRequest` message over NATS — every other module that has help documentation responds by publishing a `help.update` message, which the help module ingests into its registry. This means help content is always current without any static configuration; modules self-register on startup.

## Features

- Self-registering help system — modules publish their help docs over NATS; no manual config needed
- `!help` command — lists all registered modules, or shows detailed help for a specific module
- `!bots` command — responds with bot maintainer, URL, and help instructions (standard IRC bot metadata)
- Per-module help with parameters — registered help items include command descriptions and parameter docs (required/optional)
- Prometheus metrics — command executions, registry operations, processing time, and error tracking
- Health checks and graceful shutdown

## Usage

### `!help`

Lists all modules that have registered help documentation.

```none
!help
```

```none
Available modules with help:
- calculator
- dice
- tell
- weather

Use `help <module>` to get help for a specific module.
```

### `!help <module>`

Shows detailed help for a specific module, including commands and parameters.

```none
!help tell
```

```none
Help for `tell`:
- `tell`: Leave a message for another user
  Parameters:
    - username (required): The user to leave a message for
    - message (required): The message content
- `rmtell`: Remove a pending message you sent
  Parameters:
    - message-id (required): The ID of the message to remove
```

### `!bots` / `.bots`

Standard IRC-style bot metadata response. Matches both `!bots` / `.bots` (raw, no platform prefix) and the platform-prefixed form (e.g. `eevee: bots`).

```none
.bots
```

```none
maintainer: goos | url: https://eevee.bot | help: "eevee: help"
```

## Help Registration Format

Modules publish a JSON payload to the `help.update` NATS subject with this structure:

```typescript
interface HelpRegistration {
  from: string;        // Module name, e.g. "tell"
  help: HelpItem[];
}

interface HelpItem {
  command: string;       // Command name, e.g. "tell"
  descr: string;         // Description, e.g. "Leave a message for another user"
  params?: HelpItemParam[];
}

interface HelpItemParam {
  param: string;      // Parameter name, e.g. "username"
  required: boolean;  // Whether the parameter is required
  descr: string;      // Parameter description
}
```

Example payload published by a module at startup:

```json
{
  "from": "tell",
  "help": [
    {
      "command": "tell",
      "descr": "Leave a message for another user",
      "params": [
        { "param": "username", "required": true, "descr": "The user to leave a message for" },
        { "param": "message", "required": true, "descr": "The message content" }
      ]
    }
  ]
}
```

### NATS Subjects

| Subject | Direction | Purpose |
|---------|-----------|---------|
| `help.update` | Inbound | Modules publish their `HelpRegistration` payloads here |
| `help.remove` | Inbound | Modules request removal of their help entries |
| `help.updateRequest` | Outbound / Inbound | Help module requests all modules re-send their docs; modules may also request a full refresh |
| `help.updateRequest.*` | Inbound | Module-specific update request (e.g. `help.updateRequest.tell`) |
| `command.execute.{uuid}` | Inbound | Router dispatches matched `!help` / `!bots` commands here |
| `command.register` | Outbound | Registers command definitions with the router |
| `sendChatMessage` | Outbound | Sends help/bots responses back to the chat connector |

## Configuration

To deploy the help module, add it to your bot's `botModules` configuration with `moduleName: "help"`:

```yaml
botModules:
- name: help
  spec:
    size: 1
    image: ghcr.io/eeveebot/help:latest
    pullPolicy: Always
    metrics: true
    metricsPort: 8080
    ipcConfig: my-eevee-bot
    moduleName: help
```

The help module has no module-specific configuration keys beyond the standard rate limiting options. Help content is populated dynamically from other modules at runtime.
