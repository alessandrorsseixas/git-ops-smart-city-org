#!/bin/bash
# Script Master de Deploy da Infraestrutura Smart City
# Este script executa todos os deployments da infraestrutura em sequência

set -e  # Parar execução em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configurações
NAMESPACE="infrastructure"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
START_TIME=$(date +%s)

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
    echo -e "${CYAN}ℹ️  $1${NC}"
}

header() {
    echo -e "${PURPLE}🚀 $1${NC}"
}

# Função para calcular tempo decorrido
elapsed_time() {
    local end_time=$(date +%s)
    local elapsed=$((end_time - START_TIME))
    echo "$elapsed"
}

# Verificar pré-requisitos
check_prerequisites() {
    header "VERIFICANDO PRÉ-REQUISITOS"
    log "Verificando pré-requisitos do sistema..."

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

    # Verificar se minikube está instalado
    if ! command -v minikube &> /dev/null; then
        error "minikube não está instalado ou não está no PATH"
        exit 1
    fi

    # Verificar conexão com cluster
    if ! kubectl cluster-info &> /dev/null; then
        error "Não foi possível conectar ao cluster Kubernetes"
        exit 1
    fi

    # Verificar se minikube está rodando
    if ! minikube status | grep -q "Running"; then
        warning "Minikube não está rodando. Iniciando..."
        minikube start
    fi

    success "Pré-requisitos verificados com sucesso"
    echo
}

# Criar namespace se não existir
create_namespace() {
    header "CRIANDO NAMESPACE"
    log "Verificando namespace $NAMESPACE..."

    if ! kubectl get namespace $NAMESPACE &> /dev/null; then
        log "Criando namespace $NAMESPACE..."
        kubectl create namespace $NAMESPACE
        success "Namespace $NAMESPACE criado"
    else
        success "Namespace $NAMESPACE já existe"
    fi
    echo
}

# Executar script com tratamento de erro
run_script() {
    local script_path="$1"
    local script_name="$2"
    local description="$3"

    header "$description"
    log "Executando $script_name..."

    if [ -f "$script_path" ]; then
        if [ -x "$script_path" ]; then
            if bash "$script_path"; then
                success "$script_name executado com sucesso"
            else
                error "Falha ao executar $script_name"
                return 1
            fi
        else
            warning "$script_name não é executável. Tornando executável..."
            chmod +x "$script_path"
            if bash "$script_path"; then
                success "$script_name executado com sucesso"
            else
                error "Falha ao executar $script_name"
                return 1
            fi
        fi
    else
        warning "Script $script_path não encontrado. Pulando..."
    fi
    echo
}

# Deploy do Ingress (primeiro, pois outros serviços dependem dele)
deploy_ingress() {
    run_script "$BASE_DIR/ingress-deploy/deploy-infrastructure-ingress.sh" "Ingress Deployment" "DEPLOYING INGRESS CONTROLLER"
}

# Deploy dos bancos de dados
deploy_databases() {
    header "DEPLOYING DATABASES"

    # PostgreSQL
    run_script "$BASE_DIR/postgres-deploy/deploy.sh" "PostgreSQL Deployment" "  📊 PostgreSQL"

    # Redis
    run_script "$BASE_DIR/redis-deploy/deploy-redis.sh" "Redis Deployment" "  🔴 Redis"

    echo
}

# Deploy dos serviços de mensageria
deploy_messaging() {
    header "DEPLOYING MESSAGING SERVICES"

    # RabbitMQ
    run_script "$BASE_DIR/rabbitmq-deploy/deploy-rabbitmq.sh" "RabbitMQ Deployment" "  🐰 RabbitMQ"

    echo
}

# Deploy dos serviços de monitoramento
deploy_monitoring() {
    header "DEPLOYING MONITORING SERVICES"

    # Prometheus
    run_script "$BASE_DIR/prometheus-deploy/deploy-prometheus.sh" "Prometheus Deployment" "  📈 Prometheus"

    echo
}

# Deploy dos serviços de GitOps
deploy_gitops() {
    header "DEPLOYING GITOPS SERVICES"

    # GitOps services can be added here in the future
    info "Nenhum serviço GitOps configurado no momento"

    echo
}

# Configurar /etc/hosts automaticamente
configure_hosts() {
    header "CONFIGURANDO /etc/hosts"
    log "Configurando domínios no /etc/hosts..."

    local minikube_ip

    # Tentar obter IP do Minikube de diferentes maneiras
    if [[ "$EUID" -eq 0 ]]; then
        # Quando executado como root, tentar usar o usuário original
        if [ -n "$SUDO_USER" ]; then
            minikube_ip=$(sudo -u $SUDO_USER minikube ip 2>/dev/null)
        fi
    else
        minikube_ip=$(minikube ip 2>/dev/null)
    fi

    # Se ainda não conseguiu, tentar método alternativo
    if [ -z "$minikube_ip" ]; then
        # Método alternativo: verificar se há um cluster minikube rodando
        if kubectl config current-context 2>/dev/null | grep -q "minikube"; then
            # Tentar obter IP via kubectl
            minikube_ip=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null)
        fi
    fi

    if [ -z "$minikube_ip" ]; then
        warning "Não foi possível obter o IP do Minikube automaticamente"
        info "Configure manualmente no /etc/hosts:"
        echo "  # Substitua MINIKUBE_IP pelo IP do seu Minikube (execute: minikube ip)"
        echo "  MINIKUBE_IP postgres.dev.smartcity.local"
        echo "  MINIKUBE_IP redis.dev.smartcity.local"
        echo "  MINIKUBE_IP rabbitmq.dev.smartcity.local"
        echo "  MINIKUBE_IP prometheus.dev.smartcity.local"
        echo "  MINIKUBE_IP keycloak.dev.smartcity.local"
        echo "  MINIKUBE_IP smartcity.local"
        echo "  MINIKUBE_IP rancher.dev.smartcity.local"
        echo
        info "Para obter o IP: minikube ip"
        return 1
    fi

    info "IP do Minikube: $minikube_ip"

    # Lista de domínios a serem configurados
    local domains=(
        "postgres.dev.smartcity.local"
        "redis.dev.smartcity.local"
        "rabbitmq.dev.smartcity.local"
        "prometheus.dev.smartcity.local"
        "keycloak.dev.smartcity.local"
        "smartcity.local"
        "rancher.dev.smartcity.local"
    )

    # Verificar se está rodando como root
    if [[ "$EUID" -eq 0 ]]; then
        # Está rodando como root
        for domain in "${domains[@]}"; do
            if ! grep -q "$domain" /etc/hosts; then
                echo "$minikube_ip $domain" >> /etc/hosts
                success "Adicionado: $domain"
            else
                info "Já existe: $domain"
            fi
        done
        success "/etc/hosts configurado automaticamente"
    else
        # Não está rodando como root
        warning "Para configurar /etc/hosts automaticamente, execute como root:"
        echo "  sudo $0"
        echo
        info "Ou configure manualmente:"
        for domain in "${domains[@]}"; do
            echo "  $minikube_ip $domain"
        done
    fi
    echo
}

# Verificar status final
check_final_status() {
    header "VERIFICANDO STATUS FINAL"
    log "Verificando status de todos os componentes..."

    echo
    info "Namespaces:"
    kubectl get namespaces | grep -E "(infrastructure|ingress-nginx)"

    echo
    info "Pods no namespace infrastructure:"
    kubectl get pods -n infrastructure --no-headers | wc -l | xargs echo "Total de pods:"

    echo
    info "Pods por status:"
    kubectl get pods -n infrastructure --no-headers -o custom-columns=NAME:.metadata.name,STATUS:.status.phase | sort

    echo
    info "Services no namespace infrastructure:"
    kubectl get svc -n infrastructure

    echo
    info "Ingress rules:"
    kubectl get ingress -n infrastructure

    echo
    info "Pods no namespace ingress-nginx:"
    kubectl get pods -n ingress-nginx

    success "Verificação de status concluída"
    echo
}

# Mostrar informações de acesso
show_access_info() {
    header "INFORMAÇÕES DE ACESSO"
    echo
    info "=== DOMÍNIOS CONFIGURADOS ==="
    echo
    info "Bancos de Dados:"
    echo "  PostgreSQL: postgres.dev.smartcity.local"
    echo "  Redis: redis.dev.smartcity.local"
    echo
    info "Mensageria:"
    echo "  RabbitMQ: rabbitmq.dev.smartcity.local"
    echo
    info "Monitoramento:"
    echo "  Prometheus: prometheus.dev.smartcity.local"
    echo
    info "=== CONFIGURAÇÃO /etc/hosts ==="
    echo
    info "Para configurar o /etc/hosts automaticamente:"
    echo "  sudo bash -c 'echo \"\$(minikube ip) postgres.dev.smartcity.local\" >> /etc/hosts'"
    echo "  sudo bash -c 'echo \"\$(minikube ip) redis.dev.smartcity.local\" >> /etc/hosts'"
    echo "  sudo bash -c 'echo \"\$(minikube ip) rabbitmq.dev.smartcity.local\" >> /etc/hosts'"
    echo "  sudo bash -c 'echo \"\$(minikube ip) prometheus.dev.smartcity.local\" >> /etc/hosts'"
    echo
    info "Para obter o IP do Minikube:"
    echo "  minikube ip"
    echo
    info "=== PORTS DE ACESSO ==="
    echo
    info "HTTP Services (via Ingress):"
    echo "  Port: 80 (ou 30080 se usando NodePort)"
    echo
    info "TCP Services (direto):"
    echo "  PostgreSQL: 5432"
    echo "  Redis: 6379"
    echo "  RabbitMQ: 5672 (AMQP), 15672 (Management)"
    echo
}

# Mostrar resumo final
show_summary() {
    local elapsed=$(elapsed_time)
    header "DEPLOYMENT CONCLUÍDO"
    echo
    success "🎉 TODA A INFRAESTRUTURA FOI DEPLOYADA COM SUCESSO!"
    echo
    info "⏱️  Tempo total de deployment: ${elapsed}s"
    echo
    info "📋 COMPONENTES DEPLOYADOS:"
    echo "  ✅ Namespace: infrastructure"
    echo "  ✅ Ingress Controller (NGINX)"
    echo "  ✅ PostgreSQL Database"
    echo "  ✅ Redis Cache"
    echo "  ✅ RabbitMQ Message Broker"
    echo "  ✅ Prometheus Monitoring"
    echo
    info "🔍 PRÓXIMOS PASSOS:"
    echo "  1. Configurar o /etc/hosts com os domínios listados"
    echo "  2. Acesse os serviços via URLs configuradas"
    echo "  3. Verifique os logs se necessário:"
    echo "     kubectl logs -n infrastructure -l app=postgres"
    echo "     kubectl logs -n ingress-nginx deployment/nginx-ingress-ingress-nginx-controller"
    echo
    info "🧹 PARA LIMPAR TUDO:"
    echo "  kubectl delete namespace infrastructure ingress-nginx"
    echo
}

# Função principal
main() {
    echo
    echo "=========================================="
    echo "🚀 DEPLOY COMPLETO - SMART CITY INFRASTRUCTURE"
    echo "=========================================="
    echo
    info "Este script irá executar todos os deployments da infraestrutura em sequência."
    echo
    read -p "Deseja continuar? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelado pelo usuário."
        exit 0
    fi
    echo

    # Executar deployments em sequência
    check_prerequisites
    create_namespace
    deploy_ingress
    deploy_databases
    deploy_messaging
    deploy_monitoring
    deploy_gitops
    configure_hosts
    check_final_status
    show_access_info
    show_summary

    # Próximos passos
    header "PRÓXIMOS PASSOS"
    info "Infraestrutura implantada com sucesso!"
    echo
    info "Para acessar os serviços:"
    echo "  PostgreSQL:     https://postgres.dev.smartcity.local"
    echo "  Redis:          https://redis.dev.smartcity.local"
    echo "  RabbitMQ:       https://rabbitmq.dev.smartcity.local"
    echo "  Prometheus:     https://prometheus.dev.smartcity.local"
    echo
    info "Verifique se os domínios estão resolvendo:"
    echo "  ping postgres.dev.smartcity.local"
    echo
    success "Deploy concluído!"
}

# Capturar sinais de interrupção
trap 'echo -e "\n${RED}❌ Deployment interrompido pelo usuário${NC}"; exit 1' INT TERM

# Executar função principal
main "$@"
