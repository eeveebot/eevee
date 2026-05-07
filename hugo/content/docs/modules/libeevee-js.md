---
weight: 500
title: "libeevee-js"
description: "Shared Node.js library for eevee.bot modules"
draft: false
---

`@eeveebot/libeevee` is the shared TypeScript library that provides common functionality for all eevee.bot modules. Every module imports it for NATS messaging, structured logging, metrics, and signal handling.

## Installation

```bash
npm install @eeveebot/libeevee
```

## Exports

### NatsClient

The NATS client wrapper that all modules use to connect to the NATS server. Handles connection, reconnection, and subscription management.

```typescript
import { NatsClient } from '@eeveebot/libeevee';

const nats = new NatsClient();
await nats.connect('nats://localhost:4222', 'my-token');
await nats.subscribe('chat.message.incoming.>', (msg) => { ... });
await nats.publish('command.register', JSON.stringify(payload));
```

### log

Structured logger with log levels (info, warn, error, debug).

```typescript
import { log } from '@eeveebot/libeevee';

log.info('Module started', { producer: 'my-module' });
log.error('Something went wrong', { error: err.message });
```

### handleSIG

Signal handler for graceful shutdown on SIGINT/SIGTERM.

```typescript
import { handleSIG } from '@eeveebot/libeevee';

process.on('SIGINT', async () => {
  // your cleanup
  await handleSIG('SIGINT');
});
```

### eeveeLogo

The eevee.bot ASCII art logo, printed on module startup.

```typescript
import { eeveeLogo } from '@eeveebot/libeevee';
console.log(eeveeLogo);
```

### Metrics

Prometheus-compatible metrics via `prom-client`:

| Export | Type | Description |
|--------|------|-------------|
| `Counter` | Class | Prometheus counter |
| `Gauge` | Class | Prometheus gauge |
| `Histogram` | Class | Prometheus histogram |
| `uptimeGauge` | Gauge | Module uptime in seconds |
| `memoryUsageGauge` | Gauge | Process memory usage |
| `natsPublishCounter` | Counter | NATS publish operations |
| `natsSubscribeCounter` | Counter | NATS subscribe operations |
| `errorCounter` | Counter | Error count |
| `httpRequestCounter` | Counter | HTTP request count |
| `httpRequestDuration` | Histogram | HTTP request duration |
| `messageCounter` | Counter | Messages processed |
| `messageProcessingTime` | Histogram | Message processing duration |
| `connectionCounter` | Counter | Connection events |
| `connectionGauge` | Gauge | Active connections |
| `channelCounter` | Counter | Channel events |
| `channelGauge` | Gauge | Active channels |
| `commandCounter` | Counter | Commands processed |
| `commandProcessingTime` | Histogram | Command processing duration |
| `commandErrorCounter` | Counter | Command errors |
| `register` | Registry | Prometheus metric registry |
| `initializeSystemMetrics` | Function | Sets up uptime and memory gauges for a named service |
| `setupHttpServer` | Function | Starts HTTP server for Prometheus scraping |
| `recordMessage` | Function | Record a message event |
| `recordConnection` | Function | Record a connection event |
| `recordChannel` | Function | Record a channel event |
| `recordCommand` | Function | Record a command event |
| `recordCommandError` | Function | Record a command error |

### ircColors

Passthrough export of the `irc-colors` package for IRC-formatted colored text.

```typescript
import { ircColors } from '@eeveebot/libeevee';
const colored = ircColors.green('Hello');
```

## Usage in Modules

A typical module setup looks like:

```typescript
import { NatsClient, log, handleSIG, eeveeLogo } from '@eeveebot/libeevee';
import { initializeSystemMetrics, setupHttpServer } from '@eeveebot/libeevee';

console.log(eeveeLogo);
initializeSystemMetrics('my-module');
setupHttpServer({ port: process.env.HTTP_API_PORT || '9000', serviceName: 'my-module' });

const nats = new NatsClient();
// ... module logic
```

## Source

The source code lives at [`github.com/eeveebot/libeevee-js`](https://github.com/eeveebot/libeevee-js).
