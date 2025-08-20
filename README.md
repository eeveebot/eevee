# eevee

eevee, the loveable chatbot framework

Complete and utter WIP, stay tuned!

## Setup

### Requirements

- a k8s, rke2 recommended

### Operator Deployment

```bash
kubectl apply -f https://github.com/eeveebot/operator/blob/main/dist/install.yaml
```

> See [eeveebot/operator](https://github.com/eeveebot/operator) for instructions on deploying the eevee-operator

### Bot Configuration

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
