---
weight: 410
title: "Deploy Operator with Kubectl"
description: "Ok, but what's the simple way?"
draft: false
toc: true
---

## Deployment with Kubectl

Users may wish to deploy eevee-bot directly from manifests. This is how:

## Create CR files

See [custom-resources/crds](/docs/custom-resources/crds) for sample CustomResources

## Apply CR files

```bash
kubectl apply -f NatsCluster.yaml
kubectl apply -f Toolbox.yaml
kubectl apply -f ConnectorIrc.yaml
```
