---
weight: 153
title: "Deploy Operator with Kubectl"
description: "Ok, but what's the simple way?"
draft: false
toc: true
---

## Deployment with Kubectl

Users may wish to deploy eevee-operator directly from manifests. This is how:

## Clone the repo and apply manifests

```bash
# Clone repo
git clone git@github.com:eeveebot/operator.git

# move into the dir you just cloned the repo to
cd operator/dist

# apply crds, operator, rbac
kubectl apply --kustomize .

# apply servicemonitors (prometheus crds required)
kubectl apply -f servicemonitors.yaml
```
