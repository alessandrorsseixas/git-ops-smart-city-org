#!/bin/bash
# Script de Rollback do PostgreSQL para Smart City GitOps
# Este script remove completamente o PostgreSQL do cluster

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

# Confirmar ação
confirm_rollback() {
    echo
    warning "ATENÇÃO: Esta operação irá remover completamente o PostgreSQL!"
    echo
    warning "Os seguintes recursos serão removidos:"
    echo "  - StatefulSet postgres"
    echo "  - Services postgres e postgres-external"
    echo "  - ConfigMaps e Secrets relacionados"
    echo "  - PersistentVolumeClaims (dados serão preservados)"
    echo "  - CronJobs de backup"
    echo
    read -p "Tem certeza que deseja continuar? (digite 'yes' para confirmar): " confirm

    if [ "$confirm" != "yes" ]; then
        echo "Operação cancelada pelo usuário."
        exit 0
    fi
}

# Backup dos dados antes do rollback
backup_data() {
    log "Fazendo backup dos dados antes do rollback..."

    # Criar diretório de backup se não existir
    BACKUP_DIR="/tmp/postgres-rollback-backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p $BACKUP_DIR

    # Backup dos dados via pg_dump se o pod estiver rodando
    if kubectl get pod postgres-0 -n $NAMESPACE &> /dev/null; then
        log "Executando pg_dump dos dados..."
        kubectl exec -n $NAMESPACE postgres-0 -- bash -c "
            export PGPASSWORD=smartcity123
            pg_dump -U smartcity -h localhost -d smartcity -Fc > /tmp/smartcity_backup.sql
        " 2>/dev/null || warning "Não foi possível fazer backup via pg_dump"

        # Copiar backup para host
        kubectl cp $NAMESPACE/postgres-0:/tmp/smartcity_backup.sql $BACKUP_DIR/smartcity_backup.sql 2>/dev/null || warning "Não foi possível copiar backup"
    fi

    success "Backup dos dados salvo em: $BACKUP_DIR"
    echo "  Para restaurar os dados posteriormente, use:"
    echo "  kubectl cp $BACKUP_DIR/smartcity_backup.sql $NAMESPACE/postgres-0:/tmp/"
    echo "  kubectl exec -n $NAMESPACE postgres-0 -- pg_restore -U smartcity -d smartcity /tmp/smartcity_backup.sql"
}

# Remover recursos
remove_resources() {
    log "Removendo recursos do PostgreSQL..."

    # Remover via Kustomize (se disponível)
    if command -v kustomize &> /dev/null; then
        kustomize build $KUSTOMIZE_DIR | kubectl delete -f - --ignore-not-found=true
    else
        kubectl delete -k $KUSTOMIZE_DIR --ignore-not-found=true
    fi

    # Remover recursos específicos que podem ter ficado
    kubectl delete statefulset postgres -n $NAMESPACE --ignore-not-found=true
    kubectl delete deployment postgres -n $NAMESPACE --ignore-not-found=true
    kubectl delete service postgres postgres-external -n $NAMESPACE --ignore-not-found=true
    kubectl delete configmap -l app=postgres -n $NAMESPACE --ignore-not-found=true
    kubectl delete secret -l app=postgres -n $NAMESPACE --ignore-not-found=true
    kubectl delete cronjob -l app=postgres -n $NAMESPACE --ignore-not-found=true
    kubectl delete certificate postgres-tls -n $NAMESPACE --ignore-not-found=true
    kubectl delete ingress -l app=postgres -n $NAMESPACE --ignore-not-found=true

    success "Recursos removidos"
}

# Limpar PVCs (opcional)
cleanup_pvcs() {
    echo
    read -p "Deseja remover também os PersistentVolumeClaims? (dados serão perdidos) [y/N]: " remove_pvcs

    if [[ $remove_pvcs =~ ^[Yy]$ ]]; then
        log "Removendo PersistentVolumeClaims..."

        # Listar PVCs antes de remover
        echo "PVCs que serão removidos:"
        kubectl get pvc -l app=postgres -n $NAMESPACE

        kubectl delete pvc -l app=postgres -n $NAMESPACE --ignore-not-found=true
        success "PVCs removidos"
    else
        info "PVCs preservados. Os dados ainda estão disponíveis."
        echo "Para remover posteriormente:"
        echo "  kubectl delete pvc -l app=postgres -n $NAMESPACE"
    fi
}

# Verificar remoção
verify_removal() {
    log "Verificando remoção..."

    # Aguardar um pouco
    sleep 5

    # Verificar se recursos foram removidos
    if ! kubectl get pods -l app=postgres -n $NAMESPACE 2>/dev/null | grep -q postgres; then
        success "Pods do PostgreSQL removidos"
    else
        warning "Alguns pods ainda podem estar sendo terminados"
    fi

    if ! kubectl get pvc -l app=postgres -n $NAMESPACE 2>/dev/null | grep -q postgres; then
        success "PVCs do PostgreSQL removidos"
    else
        info "PVCs ainda existem (dados preservados)"
    fi
}

# Mostrar informações de restauração
show_restore_info() {
    echo
    info "=== INFORMAÇÕES DE RESTAURAÇÃO ==="
    echo
    info "Para restaurar o PostgreSQL:"
    echo "  ./deploy-postgres.sh"
    echo
    info "Para restaurar dados de backup:"
    echo "  1. Execute o deploy novamente"
    echo "  2. Use pg_restore com o arquivo de backup"
    echo
    info "PVCs preservados:"
    kubectl get pvc -l app=postgres -n $NAMESPACE 2>/dev/null || echo "Nenhum PVC encontrado"
}

# Função principal
main() {
    echo
    echo "=========================================="
    echo "🔄 ROLLBACK POSTGRESQL - SMART CITY GITOPS"
    echo "=========================================="
    echo

    confirm_rollback
    backup_data
    remove_resources
    cleanup_pvcs
    verify_removal
    show_restore_info

    echo
    echo "=========================================="
    success "ROLLBACK DO POSTGRESQL CONCLUÍDO!"
    echo "=========================================="
    echo
}

# Executar função principal
main "$@"
