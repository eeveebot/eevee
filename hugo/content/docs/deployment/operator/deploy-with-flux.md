---
weight: 152
title: "Deploy Operator with FluxCD"
description: "How to deploy the operator alone"
draft: false
toc: true
---

## Deployment with FluxCD - Helm Chart

To deploy with Helm (recommended), add these manifests to your flux-system Kustomization.

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: eevee-operator
  namespace: flux-system
spec:
  interval: 60m
  url: https://helm.eevee.bot/

---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: eevee-operator
  namespace: flux-system
spec:
  interval: 60m
  targetNamespace: eevee-system
  install:
    createNamespace: true
    crds: CreateReplace
  chart:
    spec:
      chart: eevee-operator
      sourceRef:
        kind: HelmRepository
        name: eevee-operator
        namespace: flux-system
      interval: 60m
  values:
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

## Deployment with FluxCD - From Manifests

To deploy the operator with FluxCD from manifests, add these manifests to flux-system Kustomization.

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: eevee-operator
  namespace: flux-system
spec:
  interval: 1m0s
  ref:
    branch: main
  url: https://github.com/eeveebot/operator
  ignore: |
    # exclude all
    /*
    # include deploy dir
    !/dist

---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: eevee-operator
  namespace: flux-system
spec:
  interval: 10m0s
  path: ./dist
  prune: false
  sourceRef:
    kind: GitRepository
    name: eevee-operator
```
