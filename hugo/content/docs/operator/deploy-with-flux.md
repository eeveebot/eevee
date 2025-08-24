---
weight: 410
title: "Deploy Operator with FluxCD"
description: "Gitops for my irc bot? It's more likely than you think!"
draft: false
toc: true
---

## Deployment with FluxCD

To deploy the operator with FluxCD, add these manifests to your set.

```yaml
# kustomization.yaml
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deploy.yaml
  - repo.yaml

# repo.yaml
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

# deploy.yaml
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
