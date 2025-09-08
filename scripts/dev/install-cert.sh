#!/usr/bin/env bash
set -euo pipefail

# install-cert.sh
# Gera certificado TLS autoassinado para o domínio e cria um Secret TLS no namespace fornecido

usage(){ cat <<EOF
Usage: $(basename "$0") [-n namespace] [-h]
EOF
}

INGRESS_HOST="rancher.local"
TLS_SECRET_NAME="tls-rancher-ingress"
CERT_FILE="./tls.crt"
KEY_FILE="./tls.key"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n) NAMESPACE="$2"; shift 2;;
    -h) usage; exit 0;;
    *) break;;
  esac
done

if [[ -z "${NAMESPACE:-}" ]]; then
  echo "NAMESPACE não fornecido. Use -n <namespace>" >&2
  exit 2
fi

if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
  echo "Gerando certificado autoassinado para $INGRESS_HOST"
  openssl req -x509 -newkey rsa:4096 -nodes -keyout "$KEY_FILE" -out "$CERT_FILE" -days 365 -subj "/CN=$INGRESS_HOST"
else
  echo "Certificado já existe. Usando arquivos existentes"
fi

kubectl -n "$NAMESPACE" delete secret "$TLS_SECRET_NAME" --ignore-not-found
kubectl -n "$NAMESPACE" create secret tls "$TLS_SECRET_NAME" --cert="$CERT_FILE" --key="$KEY_FILE"

echo "Secret TLS criado/atualizado no namespace $NAMESPACE"
