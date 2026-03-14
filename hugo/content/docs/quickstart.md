---
weight: 2
title: "Quickstart"
description: "Start here!"
draft: false
toc: true
---

> eevee, the lovable chatbot framework!

## What is eevee?

eevee is a microservices architecture chatbot framework that lives in k8s \
and consists of independent modules that communicate through a common message bus, NATS

## Getting Started

The only supported deployment method for eevee is with Helm. FluxCD is recommended.

### Installing with Helm

To install eevee using Helm, you'll first need to add the eevee Helm repository:

```bash
helm repo add eevee https://helm.eevee.bot/
helm repo update
```

Create a `values.yaml` file for your deployment. A sample values file can be found [here](values.yaml).

Then, you can install eevee with the following commands:

```bash
kubectl create ns eevee-bot

helm install eevee-crds eevee/eevee-crds \
  --namespace eevee-bot

helm install eevee eevee/eevee \
  --namespace eevee-bot \
  --values values.yaml
```

#### values.yaml

```yaml
# Sample values.yaml for eevee Helm chart
# This file shows the structure and available options for configuring eevee

# Values for operator chart
operator:
  # Enable the operator chart
  enabled: true

# Values for bot chart
bot:
  # Name of this bot
  name: eevee-bot

  # IPC Configuration
  ipcConfig:
    # Name of the IPC config resource
    name: eevee-bot

    spec:
      # NATS configuration
      nats:
        # Managed NATS deployment configuration
        managed:
          # Should the eevee-operator deploy a NATS server for us?
          enabled: true

          # NATS container image to use
          image: docker.io/nats:latest

        # NATS token authentication configuration
        token:
          # Should the eevee-operator generate a token for NATS auth?
          generate: true
          # Secret reference
          secretKeyRef:
            secret:
              name: nats-auth-secret
            key: token

  # Bot Modules
  botModules:
  - name: toolbox
    spec:
      # Number of toolbox instances to deploy
      size: 1

      # Container image to use
      image: ghcr.io/eeveebot/cli:latest

      # Image pull policy
      pullPolicy: Always

      # Enable metrics
      metrics: true

      # Metrics port
      metricsPort: 8080

      # IPC configuration name
      ipcConfig: eevee-bot

      # Module name - this identifies it as a toolbox
      moduleName: toolbox

  - name: router
    spec:
      # Number of module instances to deploy
      size: 1

      # Container image to use
      image: ghcr.io/eeveebot/router:latest

      # Image pull policy
      pullPolicy: Always

      # Enable metrics
      metrics: true

      # Metrics port
      metricsPort: 8080

      # IPC configuration name
      ipcConfig: eevee-bot

      # Module name - this identifies it as a router
      moduleName: router

      # Router configuration
      moduleConfig: |
        blocklist: []

  - name: admin
    spec:
      # Number of module instances to deploy
      size: 1

      # Container image to use
      image: ghcr.io/eeveebot/admin:latest

      # Image pull policy
      pullPolicy: Always

      # Enable metrics
      metrics: false

      # Metrics port
      metricsPort: 8080

      # IPC configuration name
      ipcConfig: eevee-bot

      # Module name
      moduleName: admin

      mountOperatorApiToken: true

      moduleConfig: |
        admins:
        - displayName: "root"
          # Unique identifier for this admin
          uuid: "0aeb8706-a7fa-4783-be4b-1856ac51af13"
          # Platforms this admin is accepted on (regex patterns)
          acceptedPlatforms:
          - "irc"
          # Authentication methods for this admin
          authentication:
            # Currently supporting IRC hostmask identification
            irc:
              hostmask: "root@localhost"
        ratelimits:
          join:
            mode: drop
            level: user
            limit: 100
            interval: 1m
          part:
            mode: drop
            level: user
            limit: 100
            interval: 1m
          showRatelimits:
            mode: drop
            level: user
            limit: 100
            interval: 1m
          moduleUptime:
            mode: drop
            level: user
            limit: 100
            interval: 1m
          moduleRestart:
            mode: drop
            level: user
            limit: 100
            interval: 1m

  - name: echo
    spec:
      # Number of module instances to deploy
      size: 1

      # Container image to use
      image: ghcr.io/eeveebot/echo:latest

      # Image pull policy
      pullPolicy: Always

      # Enable metrics
      metrics: false

      # Metrics port
      metricsPort: 8080

      # IPC configuration name
      ipcConfig: eevee-bot

      # Module name
      moduleName: echo

      # Module config
      moduleConfig: |
        ratelimit:
          mode: drop
          level: user
          limit: 5
          interval: 1m

  - name: emote
    spec:
      # Number of module instances to deploy
      size: 1

      # Container image to use
      image: ghcr.io/eeveebot/emote:latest

      # Image pull policy
      pullPolicy: Always

      # Enable metrics
      metrics: false

      # Metrics port
      metricsPort: 8080

      # IPC configuration name
      ipcConfig: eevee-bot

      # Module name
      moduleName: emote

      # Module config
      moduleConfig: |
        ratelimit:
          mode: drop
          level: user
          limit: 10
          interval: 1m

  - name: help
    spec:
      # Number of module instances to deploy
      size: 1

      # Container image to use
      image: ghcr.io/eeveebot/help:latest

      # Image pull policy
      pullPolicy: Always

      # Enable metrics
      metrics: false

      # Metrics port
      metricsPort: 8080

      # IPC configuration name
      ipcConfig: eevee-bot

      # Module name
      moduleName: help

      # Module config
      moduleConfig: |
        ratelimit:
          mode: drop
          level: user
          limit: 10
          interval: 1m

  - name: calculator
    spec:
      # Number of module instances to deploy
      size: 1

      # Container image to use
      image: ghcr.io/eeveebot/calculator:latest

      # Image pull policy
      pullPolicy: Always

      # Enable metrics
      metrics: false

      # Metrics port
      metricsPort: 8080

      # IPC configuration name
      ipcConfig: eevee-bot

      # Module name
      moduleName: calculator

      # Module config
      moduleConfig: |
        ratelimit:
          mode: drop
          level: user
          limit: 10
          interval: 1m

  - name: dice
    spec:
      # Number of module instances to deploy
      size: 1

      # Container image to use
      image: ghcr.io/eeveebot/dice:latest

      # Image pull policy
      pullPolicy: Always

      # Enable metrics
      metrics: false

      # Metrics port
      metricsPort: 8080

      # IPC configuration name
      ipcConfig: eevee-bot

      # Module name
      moduleName: dice

      # Module config
      moduleConfig: |
        ratelimit:
          mode: drop
          level: user
          limit: 10
          interval: 1m

  - name: urltitle
    spec:
      # Number of module instances to deploy
      size: 1

      # Container image to use
      image: ghcr.io/eeveebot/urltitle:latest

      # Image pull policy
      pullPolicy: Always

      # Enable metrics
      metrics: false

      # Metrics port
      metricsPort: 8080

      # IPC configuration name
      ipcConfig: eevee-bot

      # Module name
      moduleName: urltitle

      # Module config
      moduleConfig: |
        ratelimit:
          mode: drop
          level: user
          limit: 5
          interval: 1m

      envSecret:
        name: eevee-bot-urltitle-secrets

  - name: weather
    spec:
      # Number of module instances to deploy
      size: 1

      # Container image to use
      image: ghcr.io/eeveebot/weather:latest

      # Image pull policy
      pullPolicy: Always

      # Enable metrics
      metrics: false

      # Metrics port
      metricsPort: 8080

      # IPC configuration name
      ipcConfig: eevee-bot

      # Module name
      moduleName: weather

      # Module config
      moduleConfig: |
        ratelimit:
          mode: drop
          level: user
          limit: 5
          interval: 1m

      envSecret:
        name: eevee-bot-weather-secrets

      # Persistent Volume Claim
      persistentVolumeClaim:
        storageClassName: filesystem
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 1Gi

  - name: tell
    spec:
      # Number of module instances to deploy
      size: 1

      # Container image to use
      image: ghcr.io/eeveebot/tell:latest

      # Image pull policy
      pullPolicy: Always

      # Enable metrics
      metrics: false

      # Metrics port
      metricsPort: 8080

      # IPC configuration name
      ipcConfig: eevee-bot

      # Module name
      moduleName: tell

      # Module config
      moduleConfig: |
        ratelimit:
          mode: drop
          level: user
          limit: 5
          interval: 1m

      # Persistent Volume Claim
      persistentVolumeClaim:
        storageClassName: filesystem
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 1Gi

  - name: connector-irc-wetfish
    spec:
      # Number of module instances to deploy
      size: 1

      # Container image to use
      image: ghcr.io/eeveebot/connector-irc:latest

      # Image pull policy
      pullPolicy: Always

      # Enable metrics
      metrics: true

      # Metrics port
      metricsPort: 8080

      # IPC configuration name
      ipcConfig: eevee-bot

      # Module name - this identifies it as an IRC connector
      moduleName: irc

      # IRC configuration
      moduleConfig: |
        # List of IRC connections
        connections:
        # Display name for this network (no . or * or > allowed)
        - name: my-irc-network

          # Enable this connection
          enabled: true

          # IRC connection configuration
          irc:
            host: my.irc.network
            port: 6697
            ssl: true
            autoReconnect: true
            autoReconnectWait: 5000
            autoReconnectMaxRetries: 10
            autoRejoin: true
            autoRejoinWait: 5000
            autoRejoinMaxRetries: 5
            pingInterval: 30
            pingTimeout: 120

          # IRC Ident information
          ident:
            nick: eevee
            username: eevee
            gecos: eevee.bot
            version: "0.4.20"
            quitMsg: "eevee 0.4.20"

          # Actions to take after connecting
          postConnect:
          - # Join channels after connecting
            action: join
            join:
            - channel: '#eevee'

          # Send broadcast events for all received messages
          broadcastMessages: true
          # Settings related to command modules
          commands:
            # Common prefix regex to add to registered command regexes
            commonPrefixRegex: "^-"
```

This will deploy the eevee operator and all core modules to your Kubernetes cluster.

### Installing with FluxCD

For production deployments, we recommend using FluxCD for GitOps-based deployment. Our reference deployment configuration can be found in the [gitops repository](https://github.com/eeveebot/gitops).

The deployment includes:

- Custom Resource Definitions (CRDs)
- Namespace repository configuration
- Helm release configuration with all bot modules
- Namespace creation
- Secret management for sensitive configuration

## License

All eevee components are covered under `Attribution-NonCommercial-ShareAlike 4.0 International`

See [LICENSE](https://github.com/eeveebot/eevee/blob/main/LICENSE) for details.
