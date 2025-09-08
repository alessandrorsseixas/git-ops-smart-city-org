#!/usr/bin/env bash
set -euo pipefail

# install-ingress.sh
# Habilita o addon ingress do Minikube e aguarda o controller estar pronto

usage(){ cat <<EOF
Usage: $(basename "$0") [-n namespace] [-h]
EOF
}

INGRESS_NAMESPACE="ingress-nginx"
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n) NAMESPACE="$2"; shift 2;;
    -h) usage; exit 0;;
    *) break;;
  esac
done

echo "Habilitando ingress-nginx..."
minikube addons enable ingress
kubectl -n $INGRESS_NAMESPACE rollout status deployment/ingress-nginx-controller --timeout=5m

echo "Ingress controller pronto."
