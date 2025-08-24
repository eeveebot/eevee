---
weight: 110
title: "Getting Started"
draft: false
toc: true
---

## Requirements

- a k8s, rke2 recommended

## Option 1 - Helm

See [helm.eevee.bot](https://helm.eevee.bot) for helm details

## Option 2 - Manifests

### Operator Deployment

```bash
kubectl apply -f https://github.com/eeveebot/operator/blob/main/dist/install.yaml
```

> See [eeveebot/operator](https://github.com/eeveebot/operator) for instructions on deploying the eevee-operator

### Bot Deployment

#### toolbox.yaml

The toolbox comes with the eevee-cli and some other helpful utilities.

```yaml
---
apiVersion: eevee.bot/v1alpha1
kind: Toolbox
metadata:
  name: toolbox
  namespace: my-eevee-bot
spec: {}
```

> See [eevee_v1alpha1_toolbox.yaml](https://github.com/eeveebot/operator/blob/main/src/config/samples/eevee_v1alpha1_toolbox.yaml) for complete example.
