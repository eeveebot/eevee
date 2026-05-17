---
weight: 120
title: "cli"
description: "System observability and real-time monitoring for eevee-bot"
draft: false
---

The CLI module provides real-time system observability for an eevee-bot deployment. It connects to the NATS messaging backbone, tracks module health and connector status, detects anomalies, and displays periodic summary tables — giving operators a live dashboard of the entire bot infrastructure.

A companion Docker image (the **toolbox**) packages the monitor into a lightweight Alpine container with the NATS CLI utility pre-installed, making it easy to run debugging sessions alongside your eevee workloads in Kubernetes.

## Features

- **Real-time system observability** — tracks module health, connector status, and registrations across the deployment
- **Periodic summary tables** — 9-column ASCII table with version, uptime, message/command counts, errors, memory, and p50/p95 latency percentiles
- **Event detection** — 12 event types covering module lifecycle, connector changes, registration activity, and anomalies
- **Anomaly detection** — automatic restart detection, error delta tracking, stale module detection, connector channel count changes
- **Two renderers** — follow mode (colored events + summary tables) and raw mode (unformatted NATS firehose)
- **CRD-driven configuration** — `summaryInterval`, `maxModuleAge`, `displayEvents`, and `filters` configurable via YAML
- **Container-friendly** — forces ANSI colors for `kubectl logs` / k9s
- **Stats reporting** — monitor reports its own module/connector counts and event throughput

## Usage

### Follow Mode (default)

Displays real-time events as timestamped lines, plus a periodic summary table:

```bash
eevee monitor
```

Example output:

```
04:12:03 ▸ module appeared: weather
04:12:03 ▸ module appeared: router
04:12:08 ▸ connector-irc:libera reconnected
04:13:03 ▸ admin errors increased by 2 (0 → 2)

──────────────────────────────────────────────────────────
  eevee monitor · 04:13 UTC · 12 modules · 1 connector
──────────────────────────────────────────────────────────
  Module          Ver      Uptime   Msgs    Cmds  Errs    Mem   MsgLat     CmdLat
  ● admin         2.7.3     2h15m   1.2k      43     2   58MB  3/12ms    15/89ms
  ● router        2.5.5     2h15m   4.1k     210     0   72MB  1/5ms     8/34ms
  ○ seen          1.5.5     2h15m     86       5     0   42MB  —         —
  ● connector-irc 1.6.6     2h15m   3.8k       0     0   65MB  2/8ms     —
  ...

  IRC: libera ● connected  #eevee,#testing
──────────────────────────────────────────────────────────
```

#### Summary Table Columns

| Column | Description |
|--------|-------------|
| Module | Status dot + name (truncated at 15 chars) |
| Ver | Module version |
| Uptime | Time since module started |
| Msgs | Total messages processed |
| Cmds | Total commands executed |
| Errs | Total errors |
| Mem | RSS memory in MB |
| MsgLat | Message processing latency (p50/p95 in ms) |
| CmdLat | Command processing latency (p50/p95 in ms) |

#### Status Dots

| Symbol | Status | Meaning |
|--------|--------|---------|
| ● (green) | healthy | Running, no errors |
| ● (yellow) | degraded | Running, but has errors |
| ○ (red) | down | No recent stats (stale) or uptime is zero |

### Raw Mode

Dumps every NATS message unformatted — useful for low-level debugging:

```bash
eevee monitor --raw
```

Example output:

```
[stats.emit.response.weather] {"module":"weather","stats":{"version":"1.4.5",...}}
[command.register] {"module":"admin","command":"health"}
[control.connectors.irc.libera] {"action":"connect","network":"libera"}
```

### Options

| Flag | Default | Description |
|------|---------|-------------|
| `--follow` | on | Append-only stdout mode with colored events and periodic summary tables |
| `--raw` | off | Unformatted NATS firehose — prints every message as `[subject] payload` |
| `--filter <prefix>` | (none) | Only observe messages matching this subject prefix |
| `--modules <list>` | (all) | Only track specified modules (comma-separated) |
| `--no-summary` | off | Disable periodic summary blocks (events still shown) |
| `--no-color` | off | Strip ANSI colors from output |

## Events

The monitor observes 12 event types across the NATS backbone:

| Event | Description |
|-------|-------------|
| `module_start` | New module appeared, or module recovered from down/degraded |
| `module_stop` | Module went down or stopped responding |
| `module_error` | Module's error count increased |
| `connector_connect` | Connector appeared or status changed to connected |
| `connector_disconnect` | Connector disconnected |
| `connector_reconnect` | Connector reconnected after being disconnected |
| `registration` | Command, broadcast, or help entry registered |
| `unregistration` | Command, broadcast, or help entry removed |
| `backup_start` | Backup operation started |
| `backup_complete` | Backup operation completed |
| `backup_failed` | Backup operation failed |
| `stats_anomaly` | Module restarted, went stale, or connector lost/gained channels |

Some events are **suppressed** from the stdout renderer (first-cycle discovery, passive anomaly detection, stale module detection) — they're still processed for state tracking, but not printed as event lines. Raw mode (`--raw`) shows everything.

## NATS Subjects

### Inbound (subscribed)

| Subject | Purpose |
|---------|---------|
| `stats.emit.>` | Passive anomaly detection between summary cycles |
| `control.connectors.>` | Connector lifecycle events |
| `command.register` | Command registration notifications |
| `command.unregister` | Command unregistration notifications |
| `broadcast.register` | Broadcast registration notifications |
| `broadcast.unregister` | Broadcast unregistration notifications |
| `help.update` | Help entry updates |
| `help.remove` | Help entry removals |
| `control.registerCommands.>` | Router command re-registration sweeps |
| `control.registerBroadcasts.>` | Router broadcast re-registration sweeps |
| `stats.emit.request` | Stats collection requests (monitor responds with its own stats) |
| `stats.uptime` | Uptime queries |

### Outbound (published)

| Subject | Purpose |
|---------|---------|
| `stats.emit.request` | Fan-out to collect stats from all modules (with reply channel) |
| `stats.emit.response.<uuid>` | Reply channel for stats collection responses |

## Configuration

To deploy the CLI module, add it to your bot's `botModules` configuration with `moduleName: "cli"`:

```yaml
botModules:
- name: cli
  spec:
    size: 1
    image: ghcr.io/eeveebot/cli:latest
    pullPolicy: Always
    ipcConfig: my-eevee-bot
    moduleName: cli
    moduleConfig: |
      monitor:
        summaryInterval: 60000
        maxModuleAge: 300000
        displayEvents:
          - module_start
          - module_error
          - connector_disconnect
          - stats_anomaly
        filters:
          - chat.irc
```

### Configuration Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `summaryInterval` | number | `60000` | Milliseconds between summary table refreshes |
| `maxModuleAge` | number | `300000` | Milliseconds before a module with no stats is considered stale |
| `displayEvents` | string[] | (all) | Event types shown in follow mode |
| `filters` | string[] | (none) | Subject prefix filters |

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `NATS_HOST` | Yes | — | NATS server URL |
| `NATS_TOKEN` | Yes | — | NATS authentication token |
| `MODULE_CONFIG_PATH` | No | — | Path to YAML config file (falls back to defaults if unset) |
| `HTTP_API_PORT` | No | `9000` | Port for metrics and health-check HTTP server |

## Toolbox Container

The toolbox image bundles `eevee monitor` as its default entrypoint. On startup, it:

1. Runs init hooks from `/eevee/hook.d/init/` (prints hostname and IP for debugging)
2. Launches `eevee monitor` in follow mode

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

## Anomaly Detection

The monitor detects anomalies by comparing current and previous module state:

- **Uptime reset** — module restarted (current uptime < previous uptime)
- **Error count increase** — any delta triggers a `module_error` event
- **Stale module** — no stats received within `maxModuleAge` → module marked down
- **Status recovery** — module transitioned from down/degraded to healthy
- **Channel count change** — connector gained or lost channels

Connector data is extracted from connector module stats responses (e.g. `connector-irc` includes a `connector` array in its stats payload).

## Monitor Stats

The monitor reports its own stats when queried via `stats.emit.request`:

| Field | Description |
|-------|-------------|
| `modules_observed` | Total modules in state table |
| `modules_healthy` | Modules with status `healthy` |
| `modules_degraded` | Modules with status `degraded` |
| `modules_down` | Modules with status `down` or stale |
| `connectors_observed` | Total connectors in state table |
| `connectors_connected` | Connectors with status `connected` |
| `events_processed` | Total events emitted to renderer |
| `summary_intervals_completed` | Number of summary cycles completed |
