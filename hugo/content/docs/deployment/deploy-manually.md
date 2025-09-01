---
weight: 110
title: "With Kubectl"
description: "Ok, but what's the simple way?"
draft: false
toc: true
---

## Deployment with Kubectl

Users may wish to deploy eevee-operator, CRDs, and eevee-bot directly from manifests. This is how:

## Clone the repo and apply operator manifests

```bash
# Clone repo
git clone git@github.com:eeveebot/operator.git

# move into the dir you just cloned the repo to
cd operator/dist

# changes to operator resources are generally not necessary
# if you want to change operator namespace, names, etc, you can use kustomize patches
#
# apply crds, operator, rbac
kubectl apply --kustomize .

# apply servicemonitors (prometheus crds required)
kubectl apply -f servicemonitors.yaml
```

## Edit Custom Resource samples

Edit the custom resource samples provided as `cr-samples.yaml`

A minimal working example that leans on defaults:

```yaml
# my-eevee-bot.yaml
---
apiVersion: eevee.bot/v1alpha1
kind: ConnectorIrc
metadata:
  name: connector-irc
  namespace: my-eevee-bot
spec:
  ircConnections:
  - name: localhost
    irc:
      host: localhost
      pingInterval: 30
      pingTimeout: 120
      port: 6667
      ssl: false
    postConnect:
      join:
      - channel: '#eevee'
        key: ""
        sequence: 1
---
apiVersion: eevee.bot/v1alpha1
kind: NatsCluster
metadata:
  name: nats-cluster
  namespace: my-eevee-bot
spec:
  namespaceOverride: my-eevee-bot
---
apiVersion: eevee.bot/v1alpha1
kind: Toolbox
metadata:
  name: toolbox
  namespace: my-eevee-bot
spec: {}
```

## Apply custom resources

```bash
kubectl apply -f my-eevee-bot.yaml
```
