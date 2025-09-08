#!/usr/bin/env bash
set -euo pipefail

# deploy-infra-dev.sh - Aplica os manifests da pasta k8s/infra/dev
# Local: scripts/dec/deploys
# Uso: ./deploy-infra-dev.sh [--dry-run] [--namespace smartcity]

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

run() {
  echo "Applying infra manifests from $INFRA_DIR to namespace $NAMESPACE"
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY RUN: kubectl apply -k $INFRA_DIR"
    exit 0
  fi

  kubectl apply -k "$INFRA_DIR"
}

run
