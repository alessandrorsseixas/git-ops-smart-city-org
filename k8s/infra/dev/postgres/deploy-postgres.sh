#!/bin/bash
# Script de Deploy do PostgreSQL para Smart City GitOps
# Este script automatiza a instalação e configuração do PostgreSQL

set -e  # Parar execução em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
NAMESPACE="smartcity"
DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KUSTOMIZE_DIR="${DEPLOY_DIR}/../.."

# Função para log
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Verificar pré-requisitos
check_prerequisites() {
    log "Verificando pré-requisitos..."

    # Verificar se kubectl está instalado
    if ! command -v kubectl &> /dev/null; then
        error "kubectl não está instalado ou não está no PATH"
        exit 1
    fi

    # Verificar se kustomize está instalado
    if ! command -v kustomize &> /dev/null; then
        warning "kustomize não está instalado. Usando kubectl apply -k"
    fi

    # Verificar conexão com cluster
    if ! kubectl cluster-info &> /dev/null; then
        error "Não foi possível conectar ao cluster Kubernetes"
        exit 1
    fi

    success "Pré-requisitos verificados com sucesso"
}

# Criar namespace se não existir
create_namespace() {
    log "Verificando namespace $NAMESPACE..."

    if ! kubectl get namespace $NAMESPACE &> /dev/null; then
        log "Criando namespace $NAMESPACE..."
        kubectl create namespace $NAMESPACE
        success "Namespace $NAMESPACE criado"
    else
        success "Namespace $NAMESPACE já existe"
    fi
}

# Aplicar configurações via Kustomize
apply_kustomize() {
    log "Aplicando configurações via Kustomize..."

    if command -v kustomize &> /dev/null; then
        kustomize build $KUSTOMIZE_DIR | kubectl apply -f -
    else
        kubectl apply -k $KUSTOMIZE_DIR
    fi

    success "Configurações aplicadas com sucesso"
}

# Aguardar PostgreSQL ficar pronto
wait_for_postgres() {
    log "Aguardando PostgreSQL ficar pronto..."

    # Aguardar StatefulSet
    kubectl wait --for=condition=ready pod -l app=postgres -n $NAMESPACE --timeout=300s

    # Aguardar Service
    kubectl wait --for=condition=available --timeout=300s deployment/postgres -n $NAMESPACE 2>/dev/null || true

    success "PostgreSQL está pronto"
}

# Verificar status dos componentes
check_status() {
    log "Verificando status dos componentes..."

    echo
    info "Pods do PostgreSQL:"
    kubectl get pods -l app=postgres -n $NAMESPACE

    echo
    info "Services do PostgreSQL:"
    kubectl get svc -l app=postgres -n $NAMESPACE

    echo
    info "PersistentVolumeClaims:"
    kubectl get pvc -l app=postgres -n $NAMESPACE

    echo
    info "ConfigMaps:"
    kubectl get configmap -l app=postgres -n $NAMESPACE

    echo
    info "Secrets:"
    kubectl get secret -l app=postgres -n $NAMESPACE
}

# Testar conectividade interna
test_internal_connection() {
    log "Testando conectividade interna..."

    # Aguardar um pouco para estabilizar
    sleep 10

    # Testar conexão via service interno
    if kubectl exec -n $NAMESPACE postgres-0 -- psql -U smartcity -d smartcity -c "SELECT version();" &> /dev/null; then
        success "Conectividade interna funcionando"
    else
        warning "Conectividade interna pode não estar funcionando completamente"
    fi
}

# Verificar backup
check_backup() {
    log "Verificando configuração de backup..."

    echo
    info "CronJobs de backup:"
    kubectl get cronjob -l app=postgres,component=backup -n $NAMESPACE

    echo
    info "Próximas execuções de backup:"
    kubectl get cronjob -l app=postgres,component=backup -n $NAMESPACE -o jsonpath='{.items[*].spec.schedule}' | tr ' ' '\n'
}

# Mostrar informações de acesso
show_access_info() {
    echo
    info "=== INFORMAÇÕES DE ACESSO ==="
    echo
    info "Acesso Interno (Cluster):"
    echo "  Host: postgres.smartcity.svc.cluster.local"
    echo "  Port: 5432"
    echo "  Database: smartcity"
    echo "  User: smartcity"
    echo "  Connection String: postgresql://smartcity:smartcity123@postgres.smartcity.svc.cluster.local:5432/smartcity"
    echo
    info "Acesso Externo (LoadBalancer):"
    echo "  Host: postgres.dev.smartcity.local"
    echo "  Port: 5432"
    echo "  Database: smartcity"
    echo "  User: smartcity"
    echo "  Connection String: postgresql://smartcity:smartcity123@postgres.dev.smartcity.local:5432/smartcity"
    echo
    info "Para testar a conectividade externa:"
    echo "  cd $DEPLOY_DIR && ./test-external-connection.sh"
    echo
    info "Para ver os logs do PostgreSQL:"
    echo "  kubectl logs -f postgres-0 -n $NAMESPACE"
    echo
    info "Para conectar diretamente:"
    echo "  kubectl exec -it postgres-0 -n $NAMESPACE -- psql -U smartcity -d smartcity"
}

# Função principal
main() {
    echo
    echo "=========================================="
    echo "🚀 DEPLOY POSTGRESQL - SMART CITY GITOPS"
    echo "=========================================="
    echo

    check_prerequisites
    create_namespace
    apply_kustomize
    wait_for_postgres
    check_status
    test_internal_connection
    check_backup
    show_access_info

    echo
    echo "=========================================="
    success "DEPLOY DO POSTGRESQL CONCLUÍDO COM SUCESSO!"
    echo "=========================================="
    echo
}

# Executar função principal
main "$@"
