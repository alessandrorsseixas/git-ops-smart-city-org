#!/usr/bin/env bash
set -euo pipefail

# run.sh - Orquestra a execução dos scripts de provisioning/dev em ordem recomendada
# Local: scripts/dev
# Objetivo: executar os scripts que preparam o ambiente local (minikube, ingress, certs, rancher)
# Uso: ./run.sh [-n namespace] [-c component1,component2] [--dry-run]

# Ordem recomendada (executa todos por padrão):
# 1) install-prereqs.sh        -> valida pré-requisitos locais (kubectl, helm, minikube, openssl)
# 2) install-minikube.sh       -> provisiona o cluster minikube (start)
# 3) install-ingress.sh        -> habilita e aguarda o ingress controller (nginx)
# 4) install-cert.sh           -> gera certificado self-signed e cria secret no cluster
# 5) install-rancher-minikube.sh -> instala Rancher via Helm
# Comentário: os scripts estão escritos para serem idempotentes e seguros para reexecução.

usage() {
  cat <<EOF
Usage: $(basename "$0") [--all] [-c components] [-n namespace] [--dry-run] [-h]

Options:
  --all           Executa todos os scripts na ordem recomendada (default)
  -c components   Lista separada por vírgula para executar apenas componentes especificados
  -n namespace    Namespace alvo para operações (quando aplicável)
  --dry-run       Não executa comandos que alteram o cluster; apenas mostra ordem
  -h              Ajuda
EOF
}

DRY_RUN=0
ALL=1
COMPONENTS=""
NAMESPACE="cattle-system"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; ALL=1; shift 1;;
    --all) ALL=1; shift 1;;
    -c) COMPONENTS="$2"; ALL=0; shift 2;;
    -n) NAMESPACE="$2"; shift 2;;
    -h) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2;;
  esac
done

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$ROOT_DIR/dev"

# Sequência de scripts (nomes relativos dentro de scripts/dev)
sequence=(
  "install-prereqs.sh"
  "install-rancher-minikube.sh"
  "install-ingress.sh"
  "install-cert.sh"
)

# Se componentes foram passados, filtrar a sequência
if [[ -n "$COMPONENTS" ]]; then
  IFS=',' read -r -a comps <<< "$COMPONENTS"
  sequence=()
  for c in "${comps[@]}"; do
    sequence+=("$c")
  done
fi

# Executa cada script na ordem definida
for s in "${sequence[@]}"; do
  script_path="$SCRIPTS_DIR/$s"
  if [[ ! -f "$script_path" ]]; then
    echo "Aviso: script não encontrado: $script_path - pulando"
    continue
  fi
  echo "\n--- Executando: $s ---"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "DRY RUN: $script_path"
    continue
  fi
  # Torna executável e executa
  chmod +x "$script_path"
  "$script_path" -n "$NAMESPACE" || {
    echo "Erro ao executar $s" >&2
    exit 1
  }
done

echo "\nExecução da sequência concluída."
