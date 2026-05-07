---
weight: 120
title: "cli"
description: "Command-line interface for eevee management"
draft: false
---

The CLI module provides command-line tools for interacting with an eevee-bot deployment. It ships two binaries — `eevee` and `eevee-monitor` — that connect to the bot's NATS messaging backbone to issue control commands and observe system activity in real time.

The CLI is designed for operators and developers who need visibility into or control over a running eevee instance without deploying a full chat connector. It relies on [`@eeveebot/libeevee`](https://github.com/eeveebot/libeevee-js) for NATS client abstractions and structured logging.

A companion Docker image (the **toolbox**) packages the CLI into a lightweight Alpine container with the NATS CLI utility pre-installed, making it easy to run debugging sessions alongside your eevee workloads in Kubernetes.

## Features

- **`eevee`** — management CLI that subscribes to specific NATS subjects (e.g. `control.connectors.irc.>`) and logs control-plane activity
- **`eevee-monitor`** — real-time message monitor that subscribes to all NATS subjects (`>`) and prints every message to stdout
- **Toolbox container** — pre-built Docker image (multi-arch: amd64/arm64) with `eevee-monitor`, `nats` CLI, and common networking tools
- Graceful shutdown — both binaries drain their NATS connections on `SIGINT`/`SIGTERM`

## Install

### From GitHub Packages

```bash
npm install -g @eeveebot/cli
```

The package is published to [GitHub Packages](https://github.com/eeveebot/cli/pkgs/npm/%40eeveebot%2Fcli). You'll need a `.npmrc` configured for the `@eeveebot` scope:

```ini
@eeveebot:registry=https://npm.pkg.github.com/
```

And authenticate with a GitHub personal access token that has `read:packages` scope.

### From Source

```bash
git clone https://github.com/eeveebot/cli.git
cd cli
npm install
```

## Configuration

Both CLI tools require two environment variables to connect to NATS:

| Variable | Required | Description |
|----------|----------|-------------|
| `NATS_HOST` | Yes | NATS server URL (e.g. `nats://nats.example.com:4222`) |
| `NATS_TOKEN` | Yes | Authentication token for the NATS server |

If either variable is missing, the CLI will exit with an error.

### NATS Subjects

- **`eevee`** subscribes to `control.connectors.irc.>` — all IRC connector control messages.
- **`eevee-monitor`** subscribes to `>` — the NATS wildcard, receiving every message across all subjects.

## Usage

### `eevee`

The management CLI. Connects to NATS and subscribes to `control.connectors.irc.>` subjects, logging all IRC connector control messages.

```bash
export NATS_HOST="nats://nats.example.com:4222"
export NATS_TOKEN="my-secret-token"
eevee
```

Example output:

```
[control.connectors.irc.freenode] {"action":"connect","network":"freenode"}
[control.connectors.irc.libera] {"action":"disconnect","network":"libera"}
```

### `eevee-monitor`

A firehose monitor. Subscribes to the NATS wildcard subject `>` and prints every message across all subjects — useful for debugging and observability.

```bash
export NATS_HOST="nats://nats.example.com:4222"
export NATS_TOKEN="my-secret-token"
eevee-monitor
```

Example output:

```
[chat.irc.freenode.#eevee] {"from":"goos","message":"hello"}
[control.connectors.irc.libera] {"action":"reconnect"}
[module.weather.request] {"location":"Berlin"}
```

Press `Ctrl+C` to gracefully drain the connection and exit.

## Architecture

```
┌─────────────────────────────────────┐
│           NATS Server               │
│   (message backbone for eevee)      │
└──────────┬──────────────┬───────────┘
           │              │
    subjects:        subjects:
  control.>           >
           │              │
   ┌───────▼──────┐  ┌───▼────────────┐
   │    eevee     │  │ eevee-monitor  │
   │  (filtered   │  │  (firehose —   │
   │   listener)  │  │  all subjects) │
   └──────────────┘  └────────────────┘
```

- Both tools share the same NATS connection setup and graceful-shutdown pattern (drain on `SIGINT`/`SIGTERM`).
- `eevee` uses the `NatsClient` wrapper from `@eeveebot/libeevee` for a higher-level subscribe API.
- `eevee-monitor` uses the `nats` library directly for maximum control over the wildcard subscription.

## Toolbox Container

The toolbox image bundles `eevee-monitor` as its default entrypoint. On startup, it:

1. Runs init hooks from `/eevee/hook.d/init/` (prints hostname and IP for debugging)
2. Launches `eevee-monitor`

```bash
docker run --rm \
  -e NATS_HOST="nats://nats.example.com:4222" \
  -e NATS_TOKEN="my-secret-token" \
  ghcr.io/eeveebot/cli:latest
```

The image also includes the [`nats` CLI](https://github.com/nats-io/natscli) for manual NATS inspection:

```bash
docker exec -it <container> bash
nats sub ">"
```

### Deploying as a Bot Module

To deploy the CLI module alongside your eevee deployment, add it to your `botModules` configuration:

```yaml
botModules:
- name: cli
  spec:
    size: 1
    image: ghcr.io/eeveebot/cli:latest
    pullPolicy: Always
    ipcConfig: my-eevee-bot
    moduleName: cli
```

## Development

```bash
git clone https://github.com/eeveebot/cli.git
cd cli
npm install
npm test          # runs eslint on app/
```

### Updating libeevee

```bash
npm run update-libraries
```

This installs the latest `@eeveebot/libeevee` from GitHub Packages.

### Building the Toolbox Image

Requires [Docker Buildx](https://docs.docker.com/build/buildx/):

```bash
docker buildx bake --file toolbox/docker-bake.hcl
```

The build uses Docker secrets for the GitHub token needed to install the npm package from GitHub Packages:

```bash
GITHUB_TOKEN=$(gh auth token) docker buildx bake --file toolbox/docker-bake.hcl
```
