---
weight: 2
title: "Quickstart"
description: "Start here!"
draft: false
toc: true
---

> eevee, the lovable chatbot framework!

## What is eevee?

eevee is a microservices architecture chatbot framework that lives in k8s \
and consists of independent modules that communicate through a common message bus, NATS

> eevee is currently a WIP and is undergoing heavy development
> Keep an eye on releases, we're getting towards a `1.0.0` soon!

---

## Helpful Links

| **Link**
| ---
| [**Homepage**](https://eevee.bot/)
| [**Documentation**](https://eevee.bot/docs)
| [**Helm Repo**](https://helm.eevee.bot)
| [**Helm Git Repo**](https://github.com/eeveebot/helm)
| [**MetaRepo**](https://github.com/eeveebot/eevee)
| [**Operator**](https://github.com/eeveebot/operator)
| [**Connector-IRC**](https://github.com/eeveebot/connector-irc)
| [**Toolbox**](https://github.com/eeveebot/toolbox)
| [**CLI**](https://github.com/eeveebot/cli)

---

## Requirements

- A k8s of your favorite flavor
  - rke2 recommended if you're unopinionated
  - kind, minikube, microk8s acceptable for development

---

## Deploy eevee-operator and eevee-bot

---

### Option 1 - Helm

The `eevee` helm chart is an opinionated deployment of `eevee-operator`, `eevee-crds`, and a single instance of `eevee-bot`.

It consists of one parent chart, `eevee`, and three dependent charts, `eevee-operator`, `eevee-crds`, and `eevee-bot`

See [helm.eevee.bot](https://helm.eevee.bot) and [github.com/eeveebot/helm](https://github.com/eeveebot/helm) for sources and examples.

See [deployment/helm](/docs/deployment/deploy-with-helm/) for info on deploying the operator and an instance of the bot together. This is the recommended method if you only want one instance of the bot.

---

### Option 2 - FluxCD

You can use FluxCD to deploy the operator either from manifests or using Helm.

See [deployment/deploy-with-flux](/docs/deployment/deploy-with-flux/) for info.

---

### Option 3 - Manifests

See [deployment/deploy-manually/](/docs/deployment/deploy-manually/) for info.

#### Operator

See [deployment/operator/deploy-manually/](/docs/deployment/operator/deploy-manually/) for info.

```bash
# tl;dr
kubectl apply -f https://github.com/eeveebot/operator/blob/main/dist/bundle.yaml
```

#### Bot Deployment

See [deployment/bot/deploy-manually/](/docs/deployment/bot/deploy-manually/) for details on the CRs that define an instance of eevee-bot.

---

## License

All eevee components are covered under `Attribution-NonCommercial-ShareAlike 4.0 International`

See [LICENSE](https://github.com/eeveebot/eevee/blob/main/LICENSE) for details.
