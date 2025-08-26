---
weight: 420
title: "Deploy Operator with Helm"
description: "I have the Helm"
draft: false
toc: true
---

## Deployment with Helm

The `eevee-bot` helm chart is an opinionated deployment of `eevee-bot`. It does not include a deployment of CRs for `eevee-operator`, or CRDs necessary to run the bot (`eevee` chart does that)

See [helm.eevee.bot](https://helm.eevee.bot) and [eeveebot/helm](https://github.com/eeveebot/helm) for details.

## Values

```yaml
---
# eevee-bot Helm values

# Use an existing secret for nats token
# Must have a key "token" with the desired token
natsAuthExistingSecret: false

# Name of secret to use/create
natsAuthSecret: nats-auth

# Namespace for the bot
botNamespace: eevee-bot

# Name of this bot
name: eevee-bot

metrics:
  enabled: true

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
          postConnect:
            join:
              - sequence: 1
                channel: '#eevee'
                key: ''
```
