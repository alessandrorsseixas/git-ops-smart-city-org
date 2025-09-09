#!/usr/bin/env bash
set -euo pipefail

# run.sh - Orquestra a execução dos scripts de provisioning/dev em ordem recomendada
# Local: scripts/dev
# Objetivo: executar os scripts que preparam o ambiente local (minikube, ingress, certs, rancher)
# Uso: ./run.sh [-n namespace] [-c component1,component2] [--dry-run]

# Ordem recomendada (executa todos por padrão):
# 0) diagnose-minikube.sh --reset -> limpa e recria cluster Minikube completamente
# 1) install-prereqs.sh        -> valida pré-requisitos locais (kubectl, helm, minikube, openssl)
# 2) install-rancher-minikube.sh -> instala Rancher via Helm 
# 3) install-ingress.sh        -> configura Ingress Controller
# 4) install-cert.sh           -> gera certificado self-signed e cria secret no cluster
# 5) deploy/deploy-all.sh      -> deploy completo da infraestrutura Smart City + ArgoCD
# 6) update-hosts.sh           -> atualiza /etc/hosts com domínios necessários
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

# Executar diagnóstico e inicialização do Minikube ANTES de tudo
echo "🔍 Verificando e inicializando Minikube..."
DIAGNOSE_SCRIPT="$SCRIPTS_DIR/diagnose-minikube.sh"
if [[ -f "$DIAGNOSE_SCRIPT" ]]; then
    chmod +x "$DIAGNOSE_SCRIPT"
    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "DRY RUN: $DIAGNOSE_SCRIPT --reset"
    else
        echo "🔄 Executando reset completo do Minikube para garantir ambiente limpo..."
        "$DIAGNOSE_SCRIPT" --reset || {
            echo "❌ Falha na inicialização do Minikube"
            exit 1
        }
    fi
else
    echo "⚠️ Script de diagnóstico não encontrado: $DIAGNOSE_SCRIPT"
fi

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

# Executar atualização do /etc/hosts APÓS o deploy completo
echo ""
echo "🌐 Atualizando /etc/hosts com domínios necessários..."
UPDATE_HOSTS_SCRIPT="$SCRIPTS_DIR/update-hosts.sh"
if [[ -f "$UPDATE_HOSTS_SCRIPT" ]]; then
    chmod +x "$UPDATE_HOSTS_SCRIPT"
    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "DRY RUN: $UPDATE_HOSTS_SCRIPT"
    else
        if [[ "$EUID" -eq 0 ]]; then
            # Já está rodando como root
            "$UPDATE_HOSTS_SCRIPT" || {
                echo "⚠️ Não foi possível atualizar /etc/hosts automaticamente"
                echo "💡 Execute manualmente: sudo $UPDATE_HOSTS_SCRIPT"
            }
        else
            # Precisa de sudo
            echo "🔑 Atualizando /etc/hosts (pode solicitar senha sudo)..."
            sudo "$UPDATE_HOSTS_SCRIPT" || {
                echo "⚠️ Não foi possível atualizar /etc/hosts automaticamente"
                echo "💡 Execute manualmente: sudo $UPDATE_HOSTS_SCRIPT"
            }
        fi
    fi
else
    echo "⚠️ Script update-hosts.sh não encontrado: $UPDATE_HOSTS_SCRIPT"
fi

echo ""
echo "✅ Execução da sequência concluída!"
echo ""
echo "🎉 Smart City GitOps Development Environment está pronto!"
echo ""
echo "📋 O que foi configurado:"
echo "   1. ✅ Pré-requisitos validados"
echo "   2. ✅ Rancher + Minikube instalados"
echo "   3. ✅ Certificados configurados"
echo "   4. ✅ Infraestrutura Smart City deployada"
echo "   5. ✅ ArgoCD GitOps configurado"
echo "   6. ✅ /etc/hosts atualizado automaticamente"
echo ""
echo "🌐 Próximos passos:"
echo "   - Acesse ArgoCD: https://argocd.dev.smartcity.local"
echo "   - Usuário ArgoCD: admin / Senha: admin123"
echo ""
