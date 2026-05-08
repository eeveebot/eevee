---
weight: 230
title: "Module Lifecycle"
description: "How eevee modules start, run, and shut down"
draft: false
toc: true
---

Every eevee module runs as a Kubernetes pod managed by the operator. This page documents the lifecycle of a module from pod creation to termination — how it starts, how health is determined, how configuration changes are handled, and how it shuts down.

## Startup Sequence

All eevee modules follow the same startup pattern, using helpers from `@eeveebot/libeevee`:

```none
1. Print ASCII logo (eeveeLogo)
2. Initialize system metrics (initializeSystemMetrics)
3. Start HTTP server (setupHttpServer) → /health + /metrics endpoints
4. Connect to NATS (NatsClient.connect)
5. Load module config (loadModuleConfig)
6. Register commands with router (registerCommand)
7. Register help entries (registerHelp)
8. Register broadcast listeners (broadcast.register)
9. Subscribe to command execution subjects (command.execute.<uuid>)
10. Register stats handlers (registerStatsHandlers)
11. Register graceful shutdown (registerGracefulShutdown)
```

The module is "ready" once it has connected to NATS and registered its commands. There is no explicit ready signal — the module is considered operational as soon as its subscriptions are in place.

## Health & Readiness

### HTTP Endpoints

`setupHttpServer()` starts an Express server with two endpoints:

| Path | Description |
|------|-------------|
| `GET /health` | Returns `{ status: "ok", timestamp, service }` — 200 if all NATS clients are connected, 503 if any are disconnected |
| `GET /metrics` | Prometheus metrics in standard format |

When `natsClients` is passed to `setupHttpServer()`, the `/health` endpoint checks each client's connectivity via `NatsClient.isClosed()`. If any client is disconnected, the endpoint returns HTTP 503. If `natsClients` is not provided, `/health` always returns 200.

The port is set via the `HTTP_API_PORT` environment variable (default `9000`).

### Kubernetes Probes

The operator sets default liveness and readiness probes on module pods:

| Probe | Type | Target | `initialDelaySeconds` | `periodSeconds` |
|-------|------|--------|----------------------|------------------|
| Liveness | HTTP GET | `/health` on `metricsPort` | 10 | 30 |
| Readiness | HTTP GET | `/health` on `metricsPort` | 5 | 10 |
| Startup | — | *(none)* | — | — |

This means:
- If a module's NATS connection drops, the readiness probe will fail (503 from `/health`) and the pod will be removed from service endpoints
- If the module stays unhealthy, the liveness probe will eventually restart the pod
- If the HTTP server crashes, Kubernetes will detect it and restart the pod

Custom probes can be set via `livenessProbe`, `readinessProbe`, and `startupProbe` fields on the BotModule spec. These accept standard Kubernetes `V1Probe` objects and override the defaults entirely.

If a module has `metrics: false`, no default probes are set (the `/health` endpoint is served on the metrics port, which is not exposed when metrics are disabled).

### Environment Variables

The operator injects these environment variables into every module container:

| Variable | Source | Description |
|----------|--------|-------------|
| `NATS_HOST` | IpcConfig secret | NATS server address |
| `NATS_TOKEN` | IpcConfig secret | NATS authentication token |
| `MODULE_CONFIG_PATH` | ConfigMap mount | Path to YAML config (`/etc/module-config/config.yaml`) |
| `HTTP_API_PORT` | BotModule spec | Port for the HTTP server |
| `NAMESPACE` | Operator | Kubernetes namespace |
| `RESOURCE_NAME` | Operator | BotModule resource name |
| `MODULE_DATA` | Operator | Path to persistent data (if PVC configured) |

Additional variables are injected when relevant:

| Variable | Condition | Description |
|----------|-----------|-------------|
| `METRICS_ENABLED` | `metrics: true` | Whether Prometheus metrics are enabled |
| `METRICS_PORT` | `metrics: true` | Port for metrics endpoint |
| `EEVEE_OPERATOR_API_TOKEN` | `mountOperatorApiToken: true` | Token for operator API |
| `EEVEE_OPERATOR_API_URL` | `mountOperatorApiToken: true` | URL for operator API |

## Configuration

### Loading Config

Modules load their configuration via `loadModuleConfig()` from `@eeveebot/libeevee`. This reads the YAML file at `MODULE_CONFIG_PATH` and parses it. If the env var is unset or the file can't be read, the provided defaults are used.

```typescript
import { loadModuleConfig } from '@eeveebot/libeevee';

interface MyConfig { ratelimit?: RateLimitConfig; greeting?: string }
const config = loadModuleConfig<MyConfig>({ greeting: 'hello' });
```

The YAML content comes from the BotModule's `spec.moduleConfig` field, which the operator writes into a ConfigMap and mounts at `/etc/module-config/config.yaml`.

### Config Reload

Config reload behavior is module-specific:

- **File watch** — Some modules (e.g., connector-irc) use `chokidar` to watch `MODULE_CONFIG_PATH` for changes. When the file changes, the module reloads its configuration without restarting.
- **Restart required** — Most modules read config once at startup. To pick up changes, the module must be restarted (via the operator's rollout restart API or by updating the BotModule resource).

There is no `SIGHUP`-based reload convention in eevee. `registerGracefulShutdown` only handles `SIGINT` and `SIGTERM`.

## Graceful Shutdown

`registerGracefulShutdown()` from `@eeveebot/libeevee` handles pod termination:

1. On `SIGINT` or `SIGTERM`: drains all NATS clients, runs optional cleanup, then calls `handleSIG()`
2. `handleSIG()` removes signal listeners and arms a force-throw on the second signal
3. A 5-second timeout also force-throws if the process hasn't exited

The double-signal behavior prevents hanging: if the first shutdown attempt doesn't complete within 5 seconds, or if a second `SIGINT`/`SIGTERM` is received, the process is force-killed.

```typescript
import { registerGracefulShutdown } from '@eeveebot/libeevee';

registerGracefulShutdown(natsClients, async () => {
  // Optional cleanup: close DB connections, flush buffers, etc.
  await db.close();
});
```

## Operator-Managed Lifecycle

### Creation

When a `botmodule` resource is created, the operator:
1. Creates a ConfigMap from `spec.moduleConfig`
2. Creates a PersistentVolumeClaim if `spec.persistentVolumeClaim` is set
3. Creates a Deployment named `eevee-<name>-module`

### Updates

When a `botmodule` resource is modified, the operator:
1. Updates the Deployment (image, replicas, ports, env vars)
2. Updates the ConfigMap if `spec.moduleConfig` changed
3. Creates the PVC if newly added (does not delete if removed)

If only the ConfigMap changed and the module doesn't watch its config file, the pod won't restart automatically. Use the operator's rollout restart API to force a restart:

```bash
curl -X POST http://eevee-eevee-operator-service:9000/api/action/restart-module \
  -H "Authorization: Bearer $EEVEE_OPERATOR_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"moduleName": "echo"}'
```

### Deletion

When a `botmodule` resource is deleted, the operator deletes the associated Deployment. Kubernetes handles terminating the pod gracefully (sends SIGTERM, waits `terminationGracePeriodSeconds`, then SIGKILL).

### Disabling

Setting `spec.enabled: false` on a BotModule causes the operator to delete its Deployment. Setting it back to `true` recreates it.
