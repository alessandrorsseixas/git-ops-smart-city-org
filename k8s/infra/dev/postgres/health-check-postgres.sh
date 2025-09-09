#!/bin/bash
# Script de Health Check do PostgreSQL para Smart City GitOps
# Este script verifica o status e saúde do PostgreSQL

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

# Verificar se PostgreSQL está instalado
check_installation() {
    log "Verificando instalação do PostgreSQL..."

    # Verificar StatefulSet
    if kubectl get statefulset postgres -n $NAMESPACE &> /dev/null; then
        success "StatefulSet postgres encontrado"
    else
        error "StatefulSet postgres não encontrado"
        return 1
    fi

    # Verificar pods
    POD_COUNT=$(kubectl get pods -l app=postgres -n $NAMESPACE --no-headers | wc -l)
    if [ "$POD_COUNT" -gt 0 ]; then
        success "Pods do PostgreSQL encontrados: $POD_COUNT"
    else
        error "Nenhum pod do PostgreSQL encontrado"
        return 1
    fi

    # Verificar services
    SVC_COUNT=$(kubectl get svc -l app=postgres -n $NAMESPACE --no-headers | wc -l)
    if [ "$SVC_COUNT" -gt 0 ]; then
        success "Services do PostgreSQL encontrados: $SVC_COUNT"
    else
        warning "Nenhum service do PostgreSQL encontrado"
    fi
}

# Verificar status dos pods
check_pod_status() {
    log "Verificando status dos pods..."

    # Verificar pods running
    RUNNING_PODS=$(kubectl get pods -l app=postgres -n $NAMESPACE --no-headers | grep Running | wc -l)
    TOTAL_PODS=$(kubectl get pods -l app=postgres -n $NAMESPACE --no-headers | wc -l)

    if [ "$RUNNING_PODS" -eq "$TOTAL_PODS" ] && [ "$TOTAL_PODS" -gt 0 ]; then
        success "Todos os pods estão running: $RUNNING_PODS/$TOTAL_PODS"
    else
        PENDING_PODS=$(kubectl get pods -l app=postgres -n $NAMESPACE --no-headers | grep Pending | wc -l)
        CRASHLOOP_PODS=$(kubectl get pods -l app=postgres -n $NAMESPACE --no-headers | grep CrashLoopBackOff | wc -l)

        if [ "$PENDING_PODS" -gt 0 ]; then
            warning "Pods pendentes: $PENDING_PODS"
        fi

        if [ "$CRASHLOOP_PODS" -gt 0 ]; then
            error "Pods em CrashLoopBackOff: $CRASHLOOP_PODS"
            return 1
        fi
    fi

    # Verificar readiness
    READY_PODS=$(kubectl get pods -l app=postgres -n $NAMESPACE --no-headers | awk '{print $2}' | grep -E '^([0-9]+)/\1$' | wc -l)
    if [ "$READY_PODS" -eq "$TOTAL_PODS" ] && [ "$TOTAL_PODS" -gt 0 ]; then
        success "Todos os pods estão ready: $READY_PODS/$TOTAL_PODS"
    else
        warning "Nem todos os pods estão ready: $READY_PODS/$TOTAL_PODS"
    fi
}

# Verificar conectividade interna
check_internal_connectivity() {
    log "Verificando conectividade interna..."

    # Testar conexão com banco de dados
    if kubectl exec -n $NAMESPACE postgres-0 -- psql -U smartcity -d smartcity -c "SELECT 1;" &> /dev/null; then
        success "Conectividade interna com banco de dados OK"
    else
        error "Falha na conectividade interna com banco de dados"
        return 1
    fi

    # Verificar versão do PostgreSQL
    VERSION=$(kubectl exec -n $NAMESPACE postgres-0 -- psql -U smartcity -d smartcity -c "SELECT version();" -t | head -1)
    if [ -n "$VERSION" ]; then
        info "Versão do PostgreSQL: $VERSION"
    fi
}

# Verificar recursos (CPU/Memória)
check_resources() {
    log "Verificando utilização de recursos..."

    # Verificar limites de recursos
    kubectl get pods -l app=postgres -n $NAMESPACE -o jsonpath='{.items[*].spec.containers[*].resources}' | jq . 2>/dev/null || warning "Não foi possível verificar recursos via jq"

    # Verificar uso atual (se metrics server estiver disponível)
    if kubectl top pods -l app=postgres -n $NAMESPACE &> /dev/null; then
        echo
        info "Utilização atual de recursos:"
        kubectl top pods -l app=postgres -n $NAMESPACE
    else
        warning "Metrics Server não disponível para verificar utilização de recursos"
    fi
}

# Verificar storage
check_storage() {
    log "Verificando storage..."

    # Verificar PVCs
    PVC_STATUS=$(kubectl get pvc -l app=postgres -n $NAMESPACE --no-headers)
    if [ -n "$PVC_STATUS" ]; then
        success "PVCs do PostgreSQL encontrados"
        echo "$PVC_STATUS"
    else
        error "Nenhum PVC do PostgreSQL encontrado"
        return 1
    fi

    # Verificar uso de disco (se possível)
    if kubectl exec -n $NAMESPACE postgres-0 -- df -h /var/lib/postgresql/data &> /dev/null; then
        echo
        info "Uso de disco no container:"
        kubectl exec -n $NAMESPACE postgres-0 -- df -h /var/lib/postgresql/data
    fi
}

# Verificar backups
check_backups() {
    log "Verificando backups..."

    # Verificar CronJobs
    CRONJOB_COUNT=$(kubectl get cronjob -l app=postgres,component=backup -n $NAMESPACE --no-headers | wc -l)
    if [ "$CRONJOB_COUNT" -gt 0 ]; then
        success "CronJobs de backup encontrados: $CRONJOB_COUNT"

        # Verificar últimas execuções
        echo
        info "Últimas execuções de backup:"
        kubectl get jobs -l app=postgres,component=backup -n $NAMESPACE --sort-by=.metadata.creationTimestamp -o custom-columns=NAME:.metadata.name,STATUS:.status.conditions[*].type,START:.status.startTime | tail -5
    else
        warning "Nenhum CronJob de backup encontrado"
    fi
}

# Verificar conectividade externa (se aplicável)
check_external_connectivity() {
    log "Verificando conectividade externa..."

    # Verificar se existe service externo
    if kubectl get svc postgres-external -n $NAMESPACE &> /dev/null; then
        success "Service externo encontrado"

        # Obter IP do LoadBalancer
        LB_IP=$(kubectl get svc postgres-external -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
        if [ -n "$LB_IP" ]; then
            info "IP do LoadBalancer: $LB_IP"

            # Testar conectividade (se nc estiver disponível)
            if command -v nc &> /dev/null && nc -z -w5 $LB_IP 5432; then
                success "Conectividade externa OK (porta 5432 aberta)"
            else
                warning "Não foi possível testar conectividade externa"
            fi
        else
            warning "IP do LoadBalancer ainda não atribuído"
        fi
    else
        info "Service externo não encontrado (apenas acesso interno)"
    fi
}

# Verificar logs recentes
check_recent_logs() {
    log "Verificando logs recentes..."

    # Últimas 10 linhas de log
    echo
    info "Últimas 10 linhas de log do PostgreSQL:"
    kubectl logs --tail=10 postgres-0 -n $NAMESPACE 2>/dev/null || warning "Não foi possível obter logs"

    # Verificar erros nos logs
    ERROR_COUNT=$(kubectl logs --since=1h postgres-0 -n $NAMESPACE 2>/dev/null | grep -i error | wc -l)
    if [ "$ERROR_COUNT" -gt 0 ]; then
        warning "Encontrados $ERROR_COUNT erros nos logs da última hora"
    else
        success "Nenhum erro encontrado nos logs recentes"
    fi
}

# Gerar relatório final
generate_report() {
    echo
    echo "=========================================="
    echo "📊 RELATÓRIO DE HEALTH CHECK - POSTGRESQL"
    echo "=========================================="
    echo
    echo "Namespace: $NAMESPACE"
    echo "Data/Hora: $(date)"
    echo

    # Status geral
    if [ $? -eq 0 ]; then
        success "STATUS GERAL: SAUDÁVEL"
    else
        error "STATUS GERAL: PROBLEMAS DETECTADOS"
    fi

    echo
    echo "=========================================="
}

# Função principal
main() {
    echo
    echo "=========================================="
    echo "🔍 HEALTH CHECK POSTGRESQL - SMART CITY"
    echo "=========================================="
    echo

    # Executar verificações
    check_installation
    check_pod_status
    check_internal_connectivity
    check_resources
    check_storage
    check_backups
    check_external_connectivity
    check_recent_logs

    generate_report
}

# Executar função principal
main "$@"
