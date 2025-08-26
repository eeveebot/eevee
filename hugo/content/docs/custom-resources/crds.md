---
weight: 510
title: "Custom Resources"
description: "The DNA of eevee-bot"
date: "2023-05-22T00:34:57+01:00"
draft: false
---

> TODO: Make this page better (at least it exists)

#### toolbox.yaml

The toolbox comes with the eevee-cli and some other helpful utilities.

See [eevee_v1alpha1_toolbox.yaml](https://github.com/eeveebot/operator/blob/main/src/config/samples/eevee_v1alpha1_toolbox.yaml) for complete example.

```yaml
---
apiVersion: eevee.bot/v1alpha1
kind: Toolbox
metadata:
  name: toolbox
  namespace: my-eevee-bot
spec:
  # Number of toolbox replicas to deploy
  size: 1
  # Override container image
  containerImage: ghcr.io/eeveebot/toolbox:latest
  # Override pull policy
  # Defaults to IfNotPresent
  pullPolicy: Always
```

#### nats.yaml

NATS is the pubsub for the bot, and is required in all deployments.

```yaml
---
apiVersion: eevee.bot/v1alpha1
kind: NatsCluster
metadata:
  name: nats-cluster
  namespace: my-eevee-bot
spec:
  #
  # See https://artifacthub.io/packages/helm/nats/nats for full configuration options
  #
  namespaceOverride: my-eevee-bot
  container:
    env:
      # Different from k8s units, suffix must be B, KiB, MiB, GiB, or TiB
      # Should be ~80% of memory limit
      GOMEMLIMIT: 3.5GiB
      TOKEN:
        valueFrom:
          secretKeyRef:
            name: nats-auth
            key: token
    merge:
      resources:
        requests:
          cpu: "2"
          memory: 4Gi
        limits:
          cpu: "2"
          memory: 4Gi
  config:
    cluster:
      enabled: true
      port: 6222
      # must be 2 or higher when jetstream is enabled
      replicas: 3

    jetstream:
      enabled: true
      fileStore:
        enabled: true
        dir: /data
        pvc:
          enabled: true
          size: 10Gi
          storageClassName: mystorageclass
      memoryStore:
        enabled: false
    nats:
      port: 4222

    leafnodes:
      enabled: false

    websocket:
      enabled: false

    mqtt:
      enabled: false

    gateway:
      enabled: false

    monitor:
      enabled: true
      port: 8222

    profiling:
      enabled: false
      port: 65432

    resolver:
      enabled: false

    merge:
      authorization:
        token: << $TOKEN >>
    patch: []

  reloader:
    enabled: true

  promExporter:
    enabled: true
    podMonitor:
      enabled: true

  service:
    enabled: true
    ports:
      nats:
        enabled: true
      leafnodes:
        enabled: true
      websocket:
        enabled: true
      mqtt:
        enabled: true
      cluster:
        enabled: true
      gateway:
        enabled: true
      monitor:
        enabled: true
      profiling:
        enabled: true

  # pod disruption budget
  podDisruptionBudget:
    enabled: true

  # service account
  serviceAccount:
    enabled: true

  natsBox:
    enabled: false # eevee-toolbox has NATS client included
```

#### Connector-IRC

Connector-IRC does exactly what it says on the can.

```yaml
---
apiVersion: eevee.bot/v1alpha1
kind: ConnectorIrc
metadata:
  name: connector-irc
  namespace: my-eevee-bot
spec:
  # Number of connector-irc replicas to deploy
  # NOTE: only 1 is supported at this time
  size: 1

  # Override container image
  containerImage: ghcr.io/eeveebot/connector-irc:latest

  # Override pull policy
  # Defaults to IfNotPresent
  pullPolicy: Always

  # Setup IRC Connections
  ircConnections:
  - name: localhost
    irc:
      host: localhost
      port: 6667
      ssl: true
      autoReconnect: true
      autoReconnectWait: 5000
      autoReconnectMaxRetries: 10
      autoRejoin: true
      autoRejoinWait: 5000
      autoRejoinMaxRetries: 5
      pingInterval: 30
      pingTimeout: 120

    ident:
      nick: eevee
      username: eevee
      gecos: eevee.bot
      version: "0.4.20"
      quitMsg: "eevee 0.4.20"

    postConnect:
      join:
        - sequence: 1
          channel: '#eevee'
          key: ''
```
