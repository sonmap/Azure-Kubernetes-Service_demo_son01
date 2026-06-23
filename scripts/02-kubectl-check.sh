#!/usr/bin/env bash
set -euo pipefail
az aks get-credentials \
  -g rg-aks-store-demo-dev-krc \
  -n aks-store-demo-dev-krc \
  --overwrite-existing
kubectl get ns
kubectl get all -n pets
kubectl get svc -n pets
