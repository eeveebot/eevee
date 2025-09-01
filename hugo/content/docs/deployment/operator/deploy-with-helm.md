---
weight: 151
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

# Enable metrics - Prometheus CRDs must exist in cluster
metrics:
  enabled: true
# Namespace for the operator
operatorNamespace: eevee-system
# Deploy the eevee-bot operator
operator:
  enabled: true
# Run a CRD update job as a helm hook
crds:
  install: true
```
