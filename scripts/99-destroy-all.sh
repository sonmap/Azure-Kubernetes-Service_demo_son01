#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STACKS=(
  "80-ai-optional"
  "70-simulators"
  "60-frontends"
  "50-backend-services"
  "40-data-services"
  "30-k8s-base"
  "20-aks"
  "10-network"
  "00-foundation"
)
for s in "${STACKS[@]}"; do
  if [ -f "$ROOT/$s/terraform.tfstate" ]; then
    echo "==== destroy $s ===="
    cd "$ROOT/$s"
    terraform init
    terraform destroy -auto-approve || true
    cd "$ROOT"
  else
    echo "skip $s: no terraform.tfstate"
  fi
done
