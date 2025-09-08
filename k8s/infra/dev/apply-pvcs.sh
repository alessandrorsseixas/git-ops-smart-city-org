#!/usr/bin/env bash
set -euo pipefail

# apply-pvcs.sh - Script para aplicar todos os PVCs da infraestrutura
# Local: k8s/infra/dev
# Objetivo: Criar todos os PersistentVolumeClaims necessários para os serviços

# Cores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

log_info() {
  echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*"
}

# Verificar se kubectl está disponível
if ! command -v kubectl &> /dev/null; then
  log_error "kubectl não encontrado. Instale kubectl primeiro."
  exit 1
fi

# Verificar se o namespace smartcity existe
if ! kubectl get namespace smartcity &> /dev/null; then
  log_warning "Namespace 'smartcity' não existe. Criando..."
  kubectl create namespace smartcity
  log_success "Namespace 'smartcity' criado."
fi

log_info "=== Aplicando PVCs da infraestrutura de desenvolvimento ==="

# Lista de PVCs para aplicar
PVCS=(
  "postgres-pvc.yaml"
  "mongodb-pvc.yaml"
  "rabbitmq-pvc.yaml"
  "redis-pvc.yaml"
  "keycloak-pvc.yaml"
  "n8n-pvc.yaml"
)

# Aplicar cada PVC
for pvc_file in "${PVCS[@]}"; do
  if [[ -f "$pvc_file" ]]; then
    log_info "Aplicando $pvc_file..."
    if kubectl apply -f "$pvc_file"; then
      log_success "$pvc_file aplicado com sucesso"
    else
      log_error "Falha ao aplicar $pvc_file"
      exit 1
    fi
  else
    log_warning "Arquivo $pvc_file não encontrado - pulando"
  fi
done

# Verificar status dos PVCs
log_info "=== Status dos PVCs ==="
kubectl get pvc -n smartcity

log_success "=== Aplicação dos PVCs concluída ==="
log_info "Para verificar os volumes:"
log_info "  kubectl get pv"
log_info "  kubectl get pvc -n smartcity"
