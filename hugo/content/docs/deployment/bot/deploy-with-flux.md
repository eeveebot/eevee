---
weight: 162
title: "Deploy Operator with FluxCD"
description: "How to deploy the operator alone"
draft: false
toc: true
---

## Deployment with FluxCD - Helm Chart

To deploy with Helm (recommended), add these manifests to your flux-system Kustomization.

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: eevee-bot
  namespace: flux-system
spec:
  interval: 60m
  url: https://helm.eevee.bot/

---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: eevee-bot
  namespace: flux-system
spec:
  interval: 60m
  targetNamespace: eevee-system
  install:
    createNamespace: true
    crds: CreateReplace
  chart:
    spec:
      chart: eevee-bot
      sourceRef:
        kind: HelmRepository
        name: eevee-bot
        namespace: flux-system
      interval: 60m
  values:
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
    # Deploy toolbox
    toolbox:
      enabled: true
    # Connectors to enable
    connectors:
      # IRC Connector instances to create
      irc:
        - name: eevee-localhost
          spec:
            # Setup IRC Connections
            ircConnections:
            - name: localhost
              irc:
                host: localhost
                port: 6667
                ssl: false
              # Actions to take after connecting
              postConnect:
                join:
                  - sequence: 1
                    channel: '#eevee'
                    key: ''
```

## Deployment with FluxCD - From Manifests

To deploy the operator with FluxCD from manifests, see [bot/deploy-manually](/docs/bot/deploy-manually) and [custom-resources/crds](/docs/custom-resources/crds).

Once you have generated those CR manifests, simply add them to your flux-system Kustomization.
