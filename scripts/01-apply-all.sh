#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STACKS=(
  "00-foundation"
  "10-network"
  "20-aks"
  "30-k8s-base"
  "40-data-services"
  "50-backend-services"
  "60-frontends"
  "70-simulators"
)
for s in "${STACKS[@]}"; do
  echo "==== apply $s ===="
  cd "$ROOT/$s"
  terraform init
  terraform apply -auto-approve
  cd "$ROOT"
done
