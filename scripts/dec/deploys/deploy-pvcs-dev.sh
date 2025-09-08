#!/usr/bin/env bash
set -euo pipefail

# deploy-pvcs-dev.sh - Aplica apenas os PVCs da pasta k8s/infra/dev
# Uso: ./deploy-pvcs-dev.sh [--namespace smartcity] [--dry-run]

NAMESPACE="smartcity"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift;;
    --namespace) NAMESPACE="$2"; shift 2;;
    -h|--help) echo "Usage: $0 [--dry-run] [--namespace <ns>]"; exit 0;;
    *) echo "Unknown arg: $1"; exit 2;;
  esac
done

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
INFRA_DIR="$ROOT_DIR/k8s/infra/dev"

# Apply PVC manifests directly
PVCS=(
  "postgres-pvc.yaml"
  "mongodb-pvc.yaml"
  "rabbitmq-pvc.yaml"
  "redis-pvc.yaml"
  "keycloak-pvc.yaml"
  "n8n-pvc.yaml"
)

for f in "${PVCS[@]}"; do
  file="$INFRA_DIR/$f"
  if [[ ! -f "$file" ]]; then
    echo "Warning: $file not found, skipping"
    continue
  fi
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY RUN: kubectl apply -f $file -n $NAMESPACE"
  else
    kubectl apply -f "$file" -n "$NAMESPACE"
  fi
done

kubectl get pvc -n "$NAMESPACE" || true
