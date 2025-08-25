---
weight: 110
title: "Getting Started"
description: "Start here!"
draft: false
toc: true
---

## Requirements

- A k8s of your favorite flavor
  - rke2 recommended if you're unopinionated
  - kind, minikube, microk8s acceptable for development

## Step 0 - Read all steps, then come back here

## Step 1 - Deploy the Operator and a Bot in one shot

### Option 1 - Helm

The `eevee` helm chart is an opinionated deployment of `eevee-operator` (includes CRDs) and a single instance of `eevee-bot`.

It consists of one parent chart, `eevee`, and two dependent charts, `eevee-operator` and `eevee-bot`

See [helm.eevee.bot](https://helm.eevee.bot) and [github.com/eeveebot/helm](https://github.com/eeveebot/helm) for sources.

See [operator/deploy-with-helm](/docs/operator/deploy-with-helm) for info.

### Option 2 - FluxCD

You can use FluxCD to deploy the operator either from manifests or using Helm.

See [operator/deploy-with-flux](/docs/operator/deploy-with-flux) for info.

### Option 3 - Manifests

### Operator Deployment

See [operator/deploy-manually](/docs/operator/deploy-manually) for info.

```bash
# tl;dr
kubectl apply -f https://github.com/eeveebot/operator/blob/main/dist/bundle.yaml
```

### Bot Deployment

See [custom-resources/crds](/docs/custom-resources/crds.md) for details on the CRs that define an instance of eevee-bot.
