---
weight: 100
title: "Writing a Module"
description: "How to build a new eevee bot module from scratch"
draft: false
toc: true
---

This guide walks through building a new eevee module from scratch. By the end, you'll have a working `!ping` module that responds to chat messages.

## Prerequisites

- Node.js 24+
- npm
- Access to the `@eeveebot` npm scope (GitHub Packages)
- A running eevee deployment to test against

## Project Setup

Create a new directory and initialize the project:

```bash
mkdir ping && cd ping
npm init -y
npm install @eeveebot/libeevee
npm install -D typescript @types/node
npx tsc --init
```

Configure `tsconfig.json` for ESM output:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "moduleResolution": "bundler",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "declaration": true
  },
  "include": ["src"]
}
```

## Module Structure

```
ping/
├── src/
│   └── main.mts      # Entry point
├── package.json
└── tsconfig.json
```

## The Module Skeleton

Every module follows the same startup pattern. Here's the skeleton:

```typescript
// src/main.mts

import fs from 'node:fs';

import {
  NatsClient,
  log,
  eeveeLogo,
  handleSIG,
  registerGracefulShutdown,
  registerCommand,
  registerBroadcast,
  registerHelp,
  registerStatsHandlers,
  loadModuleConfig,
  sendChatMessage,
  createModuleMetrics,
  initializeSystemMetrics,
  setupHttpServer,
  createNatsConnection,
  NatsSubscriptionResult,
} from '@eeveebot/libeevee';

import * as Nats from 'nats';

// Read version from package.json (used for stats and drift detection)
const { version: moduleVersion } = JSON.parse(
  fs.readFileSync(new URL('package.json', 'file://' + process.cwd() + '/'), 'utf8')
);

// Record startup time
const moduleStartTime = Date.now();

// Initialize metrics
const metrics = createModuleMetrics('ping');
initializeSystemMetrics('ping');

// Start HTTP server for /health and /metrics
setupHttpServer({
  port: process.env.HTTP_API_PORT || '9000',
  serviceName: 'ping',
});

// Print the logo
console.log(eeveeLogo);
log.info(`ping module v${moduleVersion} starting up`, { producer: 'ping' });

// Connect to NATS
const nats = await createNatsConnection();

// Load configuration
interface PingConfig { message?: string }
const config = loadModuleConfig<PingConfig>({ message: 'Pong!' });

// Register graceful shutdown
registerGracefulShutdown([nats]);

// ... register commands, help, broadcasts, subscribe to subjects ...

log.info('ping module ready', { producer: 'ping' });
```

## Registering Commands

Commands are the primary way modules interact with users. A command registration tells the router which messages to route to your module:

```typescript
const PING_COMMAND_UUID = 'your-uuid-here'; // Use a real UUID

const pingSubs = await registerCommand(
  nats,
  {
    commandUUID: PING_COMMAND_UUID,
    commandDisplayName: 'ping',
    regex: '^[!~]ping$',
    platformPrefixAllowed: true,
    ratelimit: { mode: 'drop', level: 'user', limit: 1, interval: '5s' },
  },
  metrics
);
```

The `regex` field is matched against the message text (after the bot nick or prefix is stripped). The `platformPrefixAllowed` flag lets users trigger the command with the configured prefix character (e.g., `!ping`).

## Handling Commands

Subscribe to `command.execute.<uuid>` to receive matched messages:

```typescript
await nats.subscribe(`command.execute.${PING_COMMAND_UUID}`, (subject: string, message: Nats.Msg) => {
  metrics.recordNatsSubscribe(subject);

  const data = JSON.parse(message.string());
  log.info('Received ping command', {
    producer: 'ping',
    channel: data.channel,
    user: data.user,
  });

  // Send a response back to the channel
  void sendChatMessage(
    nats,
    {
      channel: data.channel,
      network: data.network,
      instance: data.instance,
      platform: data.platform,
      text: `${data.user}: ${config.message || 'Pong!'}`,
      trace: data.trace,
    },
    metrics
  );
});
```

The command execution payload contains:

| Field | Description |
|-------|-------------|
| `platform` | Chat platform (e.g., `irc`, `discord`) |
| `network` | Network name (e.g., `libera`) |
| `instance` | Instance name (e.g., `mybot`) |
| `channel` | Channel the message came from |
| `user` | Nick of the user who sent the message |
| `text` | Message text (with the command prefix stripped) |
| `originalText` | Full original message text |
| `matchedCommand` | The command that was matched (e.g., `!ping`) |
| `trace` | Trace ID for correlating request/response |

## Registering Help

Help entries appear in the `!help` output. Register them so users can discover your commands:

```typescript
const helpSubs = await registerHelp(
  nats,
  'ping',
  [
    {
      command: 'ping',
      descr: 'Check if the bot is alive',
      params: [],
    },
  ],
  metrics
);
```

If your command takes parameters:

```typescript
{
  command: 'weather',
  descr: 'Get the weather for a location',
  params: [
    { param: 'location', required: true, descr: 'ZIP code or city name' },
    { param: 'units', required: false, descr: 'metric or imperial' },
  ],
  aliases: ['w'],
}
```

## Registering Broadcasts

Broadcasts let your module observe all messages matching a pattern. This is useful for modules that need to react to messages regardless of whether they're commands (e.g., `seen` tracking, `urltitle` link detection):

```typescript
const OBSERVER_BROADCAST_UUID = 'your-broadcast-uuid-here';

const broadcastSubs = await registerBroadcast(
  nats,
  {
    broadcastUUID: OBSERVER_BROADCAST_UUID,
    broadcastDisplayName: 'ping-observer',
  },
  metrics
);
```

Then subscribe to `broadcast.message.<uuid>` to receive matching messages. The payload format is the same as command execution.

By default, all regex filters (`platform`, `network`, `instance`, `channel`, `user`, `nick`) match `.*` (everything). To filter, pass the ones you need:

```typescript
const broadcastSubs = await registerBroadcast(
  nats,
  {
    broadcastUUID: URLTITLE_BROADCAST_UUID,
    broadcastDisplayName: 'urltitle',
    messageFilterRegex: 'https?://',  // Only messages containing URLs
  },
  metrics
);
```

The helper also subscribes to `control.registerBroadcasts` and `control.registerBroadcasts.<displayName>` for automatic re-registration.

## Version Tracking

All eevee modules report their version in the stats response. This is used by the admin `health` command to detect **version drift** — when a module's running version doesn't match the deployed image tag. Read the version from `package.json` at startup:

```typescript
import fs from 'node:fs';

const { version: moduleVersion } = JSON.parse(
  fs.readFileSync(new URL('package.json', 'file://' + process.cwd() + '/'), 'utf8')
);
```

> **Why `process.cwd()`?** In Docker, code runs from `/app/dist/main.mjs` but `package.json` is at `/app/package.json`. Using `new URL('../package.json', import.meta.url)` resolves incorrectly to `/package.json` — always use `process.cwd()` instead.

Pass the version to `registerStatsHandlers` (see below) so it's included in stats responses.

## Registering Stats Handlers

The stats system lets the CLI, admin health, and other tools query module uptime, resource usage, and version. Include the `version` field for drift detection:

```typescript
const statsSubs = registerStatsHandlers({
  nats,
  moduleName: 'ping',
  startTime: moduleStartTime,
  version: moduleVersion,
  metrics,
});
```

The `version` field is optional but strongly recommended — without it, the admin health command can't detect when a module is running an outdated image.

## Persistent Data

If your module needs to store data that survives pod restarts, add a PVC to your BotModule:

```yaml
  spec:
    persistentVolumeClaim:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi
    volumeMountPath: /data
```

The operator creates the PVC and sets the `MODULE_DATA` environment variable to the mount path (default `/data`). Use it in your module:

```typescript
const dataPath = process.env.MODULE_DATA || '/data';
const db = new Database(path.join(dataPath, 'mydata.db'));
```

## Unregistration

When a module shuts down, it should unregister its commands, broadcasts, and help entries so the router and help module don't route to a dead subscriber. libeevee provides helpers that mirror the registration ones:

```typescript
import { unregisterCommand, unregisterBroadcast, unregisterHelp } from '@eeveebot/libeevee';

// Unregister on shutdown
await unregisterCommand(nats, {
  commandUUID: PING_COMMAND_UUID,
  commandDisplayName: 'ping',
}, metrics);

await unregisterBroadcast(nats, {
  broadcastUUID: OBSERVER_BROADCAST_UUID,
  broadcastDisplayName: 'ping-observer',
}, metrics);

await unregisterHelp(nats, 'ping', metrics);
```

In practice, you typically call these in a `registerGracefulShutdown` cleanup callback. The helpers publish to `command.unregister`, `broadcast.unregister`, and `help.remove` respectively.

## Logging

Use the structured logger from libeevee — never `console.log`:

```typescript
import { log } from '@eeveebot/libeevee';

log.info('Command executed', { producer: 'ping', channel: '#general', user: 'goos' });
log.error('Database connection failed', { producer: 'ping', error: err.message });
log.debug('Processing message', { producer: 'ping', text: data.text });
```

Always include a `producer` field to identify the subsystem. In production, logs are JSON with ISO timestamps. In development, they're colorized with human-readable timestamps.

## The Complete Module

Here's the full `ping` module:

```typescript
// src/main.mts

import fs from 'node:fs';

import {
  log,
  eeveeLogo,
  registerGracefulShutdown,
  registerCommand,
  registerHelp,
  registerStatsHandlers,
  loadModuleConfig,
  sendChatMessage,
  createModuleMetrics,
  initializeSystemMetrics,
  setupHttpServer,
  createNatsConnection,
  unregisterCommand,
  unregisterHelp,
} from '@eeveebot/libeevee';

import * as Nats from 'nats';

// Read version for stats and drift detection
const { version: moduleVersion } = JSON.parse(
  fs.readFileSync(new URL('package.json', 'file://' + process.cwd() + '/'), 'utf8')
);

const moduleStartTime = Date.now();
const metrics = createModuleMetrics('ping');

initializeSystemMetrics('ping');
setupHttpServer({
  port: process.env.HTTP_API_PORT || '9000',
  serviceName: 'ping',
});

console.log(eeveeLogo);
log.info(`ping module v${moduleVersion} starting up`, { producer: 'ping' });

// Connect to NATS
const nats = await createNatsConnection();

// Load config
interface PingConfig { message?: string }
const config = loadModuleConfig<PingConfig>({ message: 'Pong!' });

// Command UUID (generate your own)
const PING_COMMAND_UUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

// Register graceful shutdown with cleanup
registerGracefulShutdown([nats], async () => {
  await unregisterCommand(nats, {
    commandUUID: PING_COMMAND_UUID,
    commandDisplayName: 'ping',
  }, metrics);
  await unregisterHelp(nats, 'ping', metrics);
});

// Register command with router
await registerCommand(
  nats,
  {
    commandUUID: PING_COMMAND_UUID,
    commandDisplayName: 'ping',
    regex: '^[!~]ping$',
    platformPrefixAllowed: true,
    ratelimit: { mode: 'drop', level: 'user', limit: 1, interval: '5s' },
  },
  metrics
);

// Subscribe to command execution
await nats.subscribe(`command.execute.${PING_COMMAND_UUID}`, (subject: string, message: Nats.Msg) => {
  metrics.recordNatsSubscribe(subject);
  const data = JSON.parse(message.string());

  void sendChatMessage(
    nats,
    {
      channel: data.channel,
      network: data.network,
      instance: data.instance,
      platform: data.platform,
      text: `${data.user}: ${config.message}`,
      trace: data.trace,
    },
    metrics
  );
});

// Register help
await registerHelp(nats, 'ping', [
  {
    command: 'ping',
    descr: 'Check if the bot is alive',
    params: [],
  },
], metrics);

// Register stats handlers (includes version for drift detection)
registerStatsHandlers({ nats, moduleName: 'ping', startTime: moduleStartTime, version: moduleVersion, metrics });

log.info('ping module ready', { producer: 'ping' });
```

### Notes on the complete module

- **Version from `package.json`** — read at startup using `process.cwd()` (not `import.meta.url`, which breaks in Docker). Passed to `registerStatsHandlers` so `admin health` can detect drift.
- **Unregistration on shutdown** — the `registerGracefulShutdown` cleanup callback unregisters the command and help entries. Without this, the router would keep routing messages to a dead subscriber until it times out.
- **Typed callbacks** — the `nats.subscribe` callback uses explicit `(subject: string, message: Nats.Msg)` types. This is required under strict mode — untyped params become implicit `any`.

## Dockerfile

Every eevee module needs a Dockerfile for containerized deployment. Here's the standard pattern used by all eevee modules:

```dockerfile
FROM docker.io/node:24-alpine AS builder

USER root

RUN set -exu \
  && apk add --no-cache \
    bash \
    make

USER node

WORKDIR /build

COPY --chown=node:node . /build

ENV NODE_ENV=development

RUN --mount=type=secret,id=GITHUB_TOKEN,env=GITHUB_TOKEN \
  set -exu \
  && cd /build \
  && npm install --include=dev \
  && npm run build

FROM docker.io/node:24-alpine

USER node
WORKDIR /app

ENV NODE_ENV=production

COPY --chown=node:node package.json package-lock.json .npmrc /app/

RUN --mount=type=secret,id=GITHUB_TOKEN,env=GITHUB_TOKEN \
  npm install

COPY --from=builder /build/dist /app/dist

ENTRYPOINT ["/bin/sh"]

CMD ["-c", "node /app/dist/main.mjs"]
```

Key points:
- **Multi-stage build** — builder stage installs dev dependencies and compiles; final stage gets only production artifacts
- **Secret-based auth** — the `GIT_TOKEN` secret is used to access `@eeveebot` packages on GitHub Package Registry. The token never touches the filesystem permanently — it's mounted, used for install, then forgotten
- **Generic ENTRYPOINT** — uses `node` as the entrypoint with `dist/main.mjs` as the default CMD, making it easy to override for debugging (`kubectl exec -it <pod> -- /bin/sh`)
- **Fully qualified image names** — always use `docker.io/node:24-slim`, never just `node:24-slim` (never assume docker.io is the runtime default)

## Deploying

Create a BotModule resource to deploy your module:

```yaml
apiVersion: eevee.bot/v1
kind: botmodule
metadata:
  name: ping
  namespace: eevee-bot
spec:
  enabled: true
  size: 1
  image: ghcr.io/eeveebot/ping:latest
  pullPolicy: Always
  metrics: true
  metricsPort: 9000
  ipcConfig: my-eevee-bot
  moduleName: ping
  moduleConfig: |
    message: "Pong! 🏓"
```

Apply it with `kubectl apply -f ping.yaml` and the operator will create the deployment.

## NATS Subject Reference

| Subject | Direction | Description |
|---------|-----------|-------------|
| `command.register` | Module → Router | Register a command |
| `command.unregister` | Module → Router | Unregister a command |
| `command.execute.<uuid>` | Router → Module | Deliver a matched command |
| `broadcast.register` | Module → Router | Register a broadcast listener |
| `broadcast.unregister` | Module → Router | Unregister a broadcast listener |
| `broadcast.message.<uuid>` | Router → Module | Deliver a matched broadcast |
| `help.update` | Module → Help | Publish help entries |
| `help.remove` | Module → Help | Remove help entries |
| `help.updateRequest` | Help → Modules | Request help re-publication |
| `chat.message.outgoing.<platform>.<instance>.>` | Module → Connector | Send a chat message |
| `control.registerCommands` | Router → Modules | Request command re-registration |
| `control.registerBroadcasts` | Router → Modules | Request broadcast re-registration |
| `stats.uptime` | CLI → Modules | Request uptime info |
| `stats.emit.request` | CLI → Modules | Request full stats |

## Next Steps

- See [Module Lifecycle](/docs/specification/module-lifecycle/) for details on health checks, shutdown, and configuration
- See [The Lifecycle of a Message](/docs/specification/incoming-messages/) for how messages flow through the system
- See [libeevee-js](/docs/modules/libeevee-js/) for the full API reference
