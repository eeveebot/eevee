---
weight: 430
title: "Deploy Operator with Helm"
description: "I have the Helm"
draft: false
toc: true
---

## Deployment with Helm

The `eevee-operator` helm chart is an opinionated deployment of `eevee-operator` and CRDs. It does not include a deployment of CRs for `eevee-bot` (`eevee` chart does that)

See [helm.eevee.bot](https://helm.eevee.bot) and [eeveebot/helm](https://github.com/eeveebot/helm) for details.

## Values

```yaml
---
# eevee-operator Helm values

# Namespace for the operator
operatorNamespace: eevee-system

# Enable metrics (prometheus CRDs must be installed first)
metrics:
  enabled: true

# Enable IronLily CRD Deployment Job
crds:
  install: true

# Enable deployment of the eevee-bot operator itself
operator:
  enabled: true
  replicas: 1
```
