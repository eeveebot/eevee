---
weight: 440
title: "github"
description: "GitHub issue creation from chat for eevee.bot"
draft: false
---

The github module lets users create GitHub issues through chat commands. After initiating issue creation, the bot sends a confirmation prompt and waits for the user to provide a description, then confirm or cancel. Issues are created on a configurable default repository via the GitHub API.

## Features

- **`github issue create <title>`** — start creating a GitHub issue with the given title
- **Confirmation flow** — after the command, the bot asks for a description; reply with the description text, then `confirm` to submit, or `cancel` to abort
- **Configurable timeout** — pending confirmations expire after a configurable period (default 10 minutes)
- **SQLite persistence** — issue records are stored in a local database for tracking
- **Rate limiting** — configurable per-user or per-channel limits to prevent spam

## Commands

| Command | Description |
|---------|-------------|
| `github issue create <title>` | Create a GitHub issue on the configured repository |

### Example

```
<user> github issue create Fix the login bug
<bot>  I'll create an issue titled "Fix the login bug" on eeveebot/eevee.
       Send a description, then say "confirm" when ready, or "cancel" to abort.
<user> The login page returns a 500 error when using SSO
<user> confirm
<bot>  Issue created: https://github.com/eeveebot/eevee/issues/42
```

Issues are labeled with `from-chat` automatically.

## Architecture

The github module uses a dynamic broadcast pattern for its confirmation flow:

1. User types `github issue create <title>` → router matches the command → module receives it via `command.execute.<uuid>`
2. Module inserts a pending issue record into SQLite and sends a confirmation prompt
3. Module registers a **scoped broadcast** for the pending issue UUID — this lets it observe the user's follow-up messages (description and confirm/cancel) without matching a command
4. When the user sends a description or `confirm`/`cancel`, the broadcast handler picks it up, validates, and either creates the issue via GitHub API or cancels
5. After resolution (confirm, cancel, or timeout), the scoped broadcast is unregistered

This pattern — registering and unregistering broadcasts on demand — avoids the module needing to observe all messages permanently.

## Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `GITHUB_PAT` | Yes | — | GitHub Personal Access Token for API access |
| `NATS_HOST` | Yes | — | NATS server hostname |
| `NATS_TOKEN` | Yes | — | NATS authentication token |
| `MODULE_CONFIG_PATH` | No | — | Path to a YAML configuration file |
| `MODULE_DATA` | Yes | — | Directory for the SQLite database |
| `HTTP_API_PORT` | No | `9000` | Port for the HTTP metrics/health server |

### YAML Configuration

```yaml
ratelimit:
  mode: drop
  level: user
  limit: 3
  interval: 1m

defaultRepo: eeveebot/eevee

# confirmationTimeoutMs: 600000  # 10 minutes
```

The `defaultRepo` field sets the target repository for issue creation. If omitted, it defaults to `eeveebot/eevee`.
