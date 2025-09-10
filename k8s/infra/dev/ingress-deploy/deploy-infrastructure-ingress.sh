#!/bin/bash
# Script de Deployment do Ingress da Infraestrutura Smart City
# Este script configura o Ingress Controller e os Ingress rules

set -e  # Parar execução em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
NAMESPACE="infrastructure"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

    # Verificar se helm está instalado
    if ! command -v helm &> /dev/null; then
        error "helm não está instalado ou não está no PATH"
        exit 1
    fi

    # Verificar conexão com cluster
    if ! kubectl cluster-info &> /dev/null; then
        error "Não foi possível conectar ao cluster Kubernetes"
        exit 1
    fi

    success "Pré-requisitos verificados com sucesso"
}

# Instalar NGINX Ingress Controller
install_ingress_controller() {
    log "Verificando NGINX Ingress Controller..."

    # Verificar se já está instalado
    if kubectl get deployment -n ingress-nginx ingress-nginx-controller &> /dev/null; then
        success "NGINX Ingress Controller já está instalado"
        return
    fi

    log "Instalando NGINX Ingress Controller..."

    # Adicionar repositório Helm
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update

    # Instalar Ingress Controller
    helm install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --create-namespace \
        --set controller.service.type=NodePort \
        --set controller.service.nodePorts.http=30080 \
        --set controller.service.nodePorts.https=30443 \
        --wait

    success "NGINX Ingress Controller instalado com sucesso"
}

# Aguardar Ingress Controller ficar pronto
wait_for_ingress_controller() {
    log "Aguardando NGINX Ingress Controller ficar pronto..."

    kubectl wait --for=condition=available --timeout=300s deployment/ingress-nginx-controller -n ingress-nginx

    success "NGINX Ingress Controller está pronto"
}

# Aplicar configurações do Ingress
apply_ingress_config() {
    log "Aplicando configurações do Ingress..."

    # Aplicar o arquivo de Ingress
    kubectl apply -f "${SCRIPT_DIR}/infrastructure-ingress.yaml"

    success "Configurações do Ingress aplicadas com sucesso"
}

# Configurar /etc/hosts para Minikube
configure_hosts_minikube() {
    log "Configurando /etc/hosts para Minikube..."

    # Obter IP do Minikube
    MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "127.0.0.1")

    # Hosts para adicionar
    HOSTS_ENTRIES="
# Smart City Infrastructure - Minikube
${MINIKUBE_IP} postgres.dev.smartcity.local
${MINIKUBE_IP} rabbitmq.dev.smartcity.local
${MINIKUBE_IP} redis.dev.smartcity.local
${MINIKUBE_IP} prometheus.dev.smartcity.local
${MINIKUBE_IP} argocd.dev.smartcity.local
${MINIKUBE_IP} grafana.dev.smartcity.local
${MINIKUBE_IP} keycloak.dev.smartcity.local
${MINIKUBE_IP} mongodb.dev.smartcity.local
${MINIKUBE_IP} app.dev.smartcity.local
${MINIKUBE_IP} api.dev.smartcity.local
"

    # Verificar se está rodando como root (necessário para modificar /etc/hosts)
    if [[ $EUID -eq 0 ]]; then
        # Backup do arquivo atual
        cp /etc/hosts /etc/hosts.backup.$(date +%Y%m%d_%H%M%S)

        # Adicionar entradas se não existirem
        if ! grep -q "postgres.dev.smartcity.local" /etc/hosts; then
            echo "$HOSTS_ENTRIES" >> /etc/hosts
            success "/etc/hosts configurado com sucesso"
        else
            success "/etc/hosts já está configurado"
        fi
    else
        warning "Para configurar /etc/hosts automaticamente, execute como root:"
        echo "sudo $0"
        echo
        info "Ou adicione manualmente ao /etc/hosts:"
        echo "$HOSTS_ENTRIES"
    fi
}

# Verificar status dos Ingress
check_ingress_status() {
    log "Verificando status dos Ingress..."

    echo
    info "Ingress criados:"
    kubectl get ingress -n infrastructure

    echo
    info "Serviços disponíveis:"
    kubectl get svc -n infrastructure

    echo
    info "Pods do Ingress Controller:"
    kubectl get pods -n ingress-nginx
}

# Mostrar informações de acesso
show_access_info() {
    echo
    info "=== INFORMAÇÕES DE ACESSO ==="
    echo
    info "URLs de acesso (via Ingress):"
    echo
    echo "🔗 PostgreSQL:     http://postgres.dev.smartcity.local"
    echo "🔗 RabbitMQ:       http://rabbitmq.dev.smartcity.local"
    echo "🔗 Redis:          http://redis.dev.smartcity.local"
    echo "🔗 Prometheus:     http://prometheus.dev.smartcity.local"
    echo "🔗 ArgoCD:         http://argocd.dev.smartcity.local"
    echo "🔗 Grafana:        http://grafana.dev.smartcity.local"
    echo "🔗 Keycloak:       http://keycloak.dev.smartcity.local"
    echo "🔗 MongoDB:        http://mongodb.dev.smartcity.local"
    echo "🔗 Smart City App: http://app.dev.smartcity.local"
    echo "🔗 Smart City API: http://api.dev.smartcity.local"
    echo
    info "Para acesso direto (Minikube):"
    echo "kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80"
    echo "Acesse: http://localhost:8080"
    echo
    info "Para verificar se os serviços estão respondendo:"
    echo "curl -H 'Host: postgres.dev.smartcity.local' http://localhost:8080"
}

# Função principal
main() {
    echo
    echo "=========================================="
    echo "🚀 DEPLOY INGRESS - SMART CITY INFRASTRUCTURE"
    echo "=========================================="
    echo

    check_prerequisites
    install_ingress_controller
    wait_for_ingress_controller
    apply_ingress_config
    configure_hosts_minikube
    check_ingress_status
    show_access_info

    echo
    echo "=========================================="
    success "DEPLOY DO INGRESS CONCLUÍDO COM SUCESSO!"
    echo "=========================================="
    echo
    echo "📋 PRÓXIMOS PASSOS:"
    echo
    echo "1. Verifique se os serviços estão acessíveis via URLs"
    echo "2. Teste a conectividade: curl -H 'Host: postgres.dev.smartcity.local' http://localhost:8080"
    echo "3. Configure aplicações para usar os domínios apropriados"
    echo "4. Para produção, configure DNS para apontar para o LoadBalancer"
    echo
}

# Executar função principal
main "$@"
