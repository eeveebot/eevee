---
weight: 120
title: "With FluxCD"
description: "Gitops for your IRC bot."
draft: false
toc: true
---

## Deployment with FluxCD - Helm Chart

To deploy eevee with Helm (recommended), add these manifests to your flux-system Kustomization.

Customize HelmRelease/eevee.spec.values as necessary for your deployment.

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: eevee
  namespace: flux-system
spec:
  interval: 60m
  url: https://helm.eevee.bot/

---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: eevee
  namespace: flux-system
spec:
  interval: 60m
  targetNamespace: eevee-system
  install:
    createNamespace: true
    crds: CreateReplace
  chart:
    spec:
      chart: eevee
      sourceRef:
        kind: HelmRepository
        name: eevee
        namespace: flux-system
      interval: 60m
  values:
    global:
      # Enable metrics - Prometheus CRDs must exist in cluster
      metrics:
        enabled: true

    eevee-operator:
      # Namespace for the operator
      operatorNamespace: eevee-system
      # Deploy the eevee-bot operator
      operator:
        enabled: true
      # Run a CRD update job as a helm hook

    eevee-crds:
      crds:
        install: true

    eevee-bot:
      # Namespace for the bot instance
      botNamespace: eevee-bot
      # Deploy NATS (disable if you want to bring your own)
      nats:
        enabled: true

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
                  - channel: '#eevee'
                    key: ""
                    sequence: 1
```

## Deployment with FluxCD - From Manifests

To deploy eevee with FluxCD from manifests, see [deployment/deploy-manually](/docs/deployment/deploy-manually) and [custom-resources/crds](/docs/custom-resources/crds).

Once you have generated those CR manifests, simply add them to your flux-system Kustomization alongside the operator and CRD manifests.

You may also use the eevee-operator git repository as a GitRepo source in Flux. See [operator/deploy-with-flux](/docs/operator/deploy-with-flux) for info on that.
