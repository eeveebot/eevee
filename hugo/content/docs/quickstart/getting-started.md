---
weight: 110
title: "Getting Started"
description: "Start here!"
draft: false
toc: true
---

## Requirements

- a k8s, rke2 recommended

## Option 1 - Helm

The eevee helm chart is an opinionated deployment of eevee-operator and a single instance of eevee-bot.

It consists of one parent chart, `eevee`, and two dependent charts, `eevee-operator` (includes CRDs) and `eevee-bot`

See [helm.eevee.bot](https://helm.eevee.bot) and [eeveebot/helm](https://github.com/eeveebot/helm) for details.

## Values

```yaml
---
# eevee Helm values

global:
  # Use an existing secret for nats token
  # Must have a key "token" with the desired token
  natsAuthExistingSecret: false

  # Name of secret to use/create
  natsAuthSecret: nats-auth
  metrics:
    enabled: true

eevee-operator:
  # Namespace for the operator
  operatorNamespace: eevee-system

  # Deploy the eevee-bot operator
  operator:
    enabled: true
    replicas: 1
  crds:
    install: true

eevee-bot:
  # Namespace for the bot
  botNamespace: eevee-bot

  # Deploy NATS cluster (disable if you want to bring your own)
  nats:
    enabled: true
    jetstream:
      fileStore:
          dir: /data
          enabled: true
          pvc:
            enabled: true
            size: 10Gi
            storageClassName: my-rwo-storage-class
      memoryStore:
        enabled: false
        # ensure that container has a sufficient memory limit greater than maxSize
        maxSize: 1Gi
  
  # Deploy toolbox
  toolbox:
    enabled: true
    spec:
       # Number of toolbox replicas to deploy
      size: 1
      # Override container image
      containerImage: ghcr.io/eeveebot/toolbox:latest
      # Override pull policy
      # Defaults to IfNotPresent
      pullPolicy: Always
  
  # Connectors to enable
  connectors:
    # IRC Connector instances to create
    irc:
      - name: eevee-localhost
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
  
            # Identifying information for the bot
            ident:
              nick: eevee
              username: eevee
              gecos: eevee.bot
              version: "0.4.20"
              quitMsg: "eevee 0.4.20"
  
            # Actions to take after connecting
            postConnect: {}
```

## Option 2 - Manifests

### Operator Deployment

```bash
kubectl apply -f https://github.com/eeveebot/operator/blob/main/dist/install.yaml
```

See [eeveebot/operator](https://github.com/eeveebot/operator) for instructions on customizing the deployment of the eevee-operator.

### Bot Deployment

See [eeveebot/operator/src/config/samples](https://github.com/eeveebot/operator/tree/main/src/config/samples) for CR examples.

#### toolbox.yaml

The toolbox comes with the eevee-cli and some other helpful utilities.

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

See [eevee_v1alpha1_toolbox.yaml](https://github.com/eeveebot/operator/blob/main/src/config/samples/eevee_v1alpha1_toolbox.yaml) for complete example.

#### nats.yaml

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

    # merge or patch the nats config
    # https://docs.nats.io/running-a-nats-service/configuration
    # following special rules apply
    #  1. strings that start with << and end with >> will be unquoted
    #     use this for variables and numbers with units
    #  2. keys ending in $include will be switched to include directives
    #     keys are sorted alphabetically, use prefix before $includes to control includes ordering
    #     paths should be relative to /etc/nats-config/nats.conf
    # example:
    #
    #   merge:
    #     $include: ./my-config.conf
    #     zzz$include: ./my-config-last.conf
    #     server_name: nats
    #     authorization:
    #       token: << $TOKEN >>
    #     jetstream:
    #       max_memory_store: << 1GB >>
    #
    # will yield the config:
    # {
    #   include ./my-config.conf;
    #   "authorization": {
    #     "token": $TOKEN
    #   },
    #   "jetstream": {
    #     "max_memory_store": 1GB
    #   },
    #   "server_name": "nats",
    #   include ./my-config-last.conf;
    # }
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
