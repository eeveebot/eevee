# eevee

eevee, the loveable chatbot framework

Complete and utter WIP, stay tuned!

## Setup

### Requirements

- a k8s, rke2 recommended

## Option 1 - Helm

### Add helm repo

```bash
helm repo add eevee https://helm.eevee.bot/
helm search repo eevee
```

### Configure values.yaml

```yaml
# values.yaml
---
botNamespace: eevee-bot
operatorNamespace: eevee-system

metrics: false

natsCluster:
  pvcSize: 10Gi
  storageClass: mystorageclass

toolbox:
  enabled: true

connectors:
  irc:
    enabled: true
    spec:
      ircConnections:
      - name: eeveebot
        ident:
          gecos: eevee.bot
          nick: eevee
          quitMsg: eevee 0.4.20
          username: eevee
          version: 0.4.20
        irc:
          autoReconnect: true
          autoReconnectMaxRetries: 10
          autoReconnectWait: 5000
          autoRejoin: true
          autoRejoinMaxRetries: 5
          autoRejoinWait: 5000
          host: localhost
          pingInterval: 30
          pingTimeout: 120
          port: 6667
          ssl: true
        postConnect:
          join:
          - channel: '#eevee'
            password: ""
            sequence: 1
```

### Helm install

```bash
helm install --upgrade eevee eevee/eevee --values eevee-values.yaml
```

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
