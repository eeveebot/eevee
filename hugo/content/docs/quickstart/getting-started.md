---
weight: 110
title: "Getting Started"
draft: false
toc: true
---

## Requirements

- a k8s, rke2 recommended

## Option 1 - Helm

The eevee helm chart is an opinionated deployment of eevee-operator and a single instance of eevee-bot.

There are plans to rework this chart into 3 charts:

- Operator
- Bot
- Meta to dep in the other two

But this has not been done yet.

See [helm.eevee.bot](https://helm.eevee.bot) and [eeveebot/helm](https://github.come/eeveebot/helm) for helm details.

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
spec: {}
```

See [eevee_v1alpha1_toolbox.yaml](https://github.com/eeveebot/operator/blob/main/src/config/samples/eevee_v1alpha1_toolbox.yaml) for complete example.

#### NATS

NATS is the core pub/sub/msq for eevee-bot.

#### Connector-IRC

Connector-IRC does exactly what it says on the can.