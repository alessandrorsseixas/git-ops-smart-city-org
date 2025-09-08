#!/usr/bin/env bash
set -euo pipefail

# install-prereqs.sh
# Valida pré-requisitos locais necessários para provisionamento do ambiente dev
# Verifica: kubectl, helm, minikube, openssl

usage(){ cat <<EOF
Usage: $(basename "$0") [-n namespace] [-h]
EOF
}

NAMESPACE="cattle-system"
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n) NAMESPACE="$2"; shift 2;;
    -h) usage; exit 0;;
    *) break;;
  esac
done

check_command(){
  command -v "$1" >/dev/null 2>&1 || { echo "ERRO: comando $1 não encontrado" >&2; exit 1; }
}

echo "Validando pré-requisitos..."
check_command kubectl
check_command helm
check_command minikube
check_command openssl

# NSSwitch check to ensure /etc/hosts resolution has priority
if [[ -f /etc/nsswitch.conf ]]; then
  if ! grep -q -E "^hosts:\s+files" /etc/nsswitch.conf; then
    echo "AVISO: /etc/nsswitch.conf não prioriza 'files'. Isso pode afetar resolução via /etc/hosts." >&2
  fi
fi

echo "Pré-requisitos validados."
