---
weight: 110
title: "With Helm"
description: "Full sails, cap'n"
draft: false
toc: true
---

## Deployment with Helm

The `eevee` helm chart is an opinionated deployment of `eevee-operator`, `eevee-crds`, and `eevee-bot`.

See [helm.eevee.bot](https://helm.eevee.bot) and [eeveebot/helm](https://github.com/eeveebot/helm) for details.

See [values.yaml](https://helm.eevee.bot/charts/eevee/values.yaml) for default values.

## Add helm repo

```bash
helm repo add eevee https://helm.eevee.bot/
helm search repo eevee
```

## Prepare values.yaml

A minimal working example that leans on defaults:

## Values

```yaml
---
# eevee Helm values
eevee-bot:
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
                - channel: "#eevee"
                  key: ""
```

## Deploy with helm

```bash
helm upgrade --install eevee eevee/eevee --values eevee-values.yaml
```
