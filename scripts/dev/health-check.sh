#!/bin/bash

# health-check.sh
# Script de verificação geral da saúde do sistema Smart City GitOps

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                        SMART CITY GITOPS HEALTH CHECK                       ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo -e "${YELLOW}┌─ $1${NC}"
}

print_info() {
    echo -e "${BLUE}   ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}   ✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}   ⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}   ❌ $1${NC}"
}

print_header

# 1. Verificar Minikube
print_section "MINIKUBE STATUS"
if command -v minikube &> /dev/null; then
    if minikube status &> /dev/null; then
        MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "N/A")
        print_success "Minikube está rodando - IP: $MINIKUBE_IP"
    else
        print_error "Minikube não está rodando"
        echo "   💡 Execute: ./diagnose-minikube.sh --start"
    fi
else
    print_error "Minikube não está instalado"
fi
echo ""

# 2. Verificar kubectl
print_section "KUBECTL CONNECTIVITY"
if command -v kubectl &> /dev/null; then
    if kubectl cluster-info &> /dev/null; then
        print_success "kubectl conectado ao cluster"
        K8S_VERSION=$(kubectl version --short 2>/dev/null | grep Server | cut -d' ' -f3 || echo "N/A")
        print_info "Kubernetes Server: $K8S_VERSION"
    else
        print_error "kubectl não consegue conectar ao cluster"
    fi
else
    print_error "kubectl não está instalado"
fi
echo ""

# 3. Verificar namespaces
print_section "NAMESPACES"
NAMESPACES=("smartcity" "argocd" "ingress-nginx" "cattle-system")
for ns in "${NAMESPACES[@]}"; do
    if kubectl get namespace "$ns" &> /dev/null; then
        print_success "Namespace $ns existe"
    else
        print_warning "Namespace $ns não encontrado"
    fi
done
echo ""

# 4. Verificar pods por namespace
print_section "PODS STATUS"

# ArgoCD
ARGOCD_PODS=$(kubectl get pods -n argocd --no-headers 2>/dev/null | wc -l)
ARGOCD_RUNNING=$(kubectl get pods -n argocd --no-headers 2>/dev/null | grep Running | wc -l)
if [ "$ARGOCD_PODS" -gt 0 ]; then
    print_success "ArgoCD: $ARGOCD_RUNNING/$ARGOCD_PODS pods rodando"
else
    print_warning "ArgoCD: Nenhum pod encontrado"
fi

# Infraestrutura
INFRA_PODS=$(kubectl get pods -n smartcity --no-headers 2>/dev/null | wc -l)
INFRA_RUNNING=$(kubectl get pods -n smartcity --no-headers 2>/dev/null | grep Running | wc -l)
if [ "$INFRA_PODS" -gt 0 ]; then
    print_success "Infraestrutura: $INFRA_RUNNING/$INFRA_PODS pods rodando"
else
    print_warning "Infraestrutura: Nenhum pod encontrado"
fi

# Ingress
INGRESS_PODS=$(kubectl get pods -n ingress-nginx --no-headers 2>/dev/null | wc -l)
INGRESS_RUNNING=$(kubectl get pods -n ingress-nginx --no-headers 2>/dev/null | grep Running | wc -l)
if [ "$INGRESS_PODS" -gt 0 ]; then
    print_success "Ingress: $INGRESS_RUNNING/$INGRESS_PODS pods rodando"
else
    print_warning "Ingress: Nenhum pod encontrado"
fi
echo ""

# 5. Verificar serviços críticos
print_section "SERVICES"
SERVICES=(
    "argocd/argocd-server"
    "smartcity/keycloak-service"
    "smartcity/postgres-service"
    "smartcity/redis-service"
    "smartcity/rabbitmq-service"
)

for svc_info in "${SERVICES[@]}"; do
    ns=$(echo "$svc_info" | cut -d'/' -f1)
    svc=$(echo "$svc_info" | cut -d'/' -f2)

    if kubectl get svc "$svc" -n "$ns" &> /dev/null; then
        print_success "Service $svc ($ns) existe"
    else
        print_warning "Service $svc ($ns) não encontrado"
    fi
done
echo ""

# 6. Verificar ingress
print_section "INGRESS"
INGRESS_COUNT=$(kubectl get ingress --all-namespaces --no-headers 2>/dev/null | wc -l)
if [ "$INGRESS_COUNT" -gt 0 ]; then
    print_success "$INGRESS_COUNT ingress configurado(s)"
    kubectl get ingress --all-namespaces --no-headers | while read -r line; do
        ns=$(echo "$line" | awk '{print $1}')
        name=$(echo "$line" | awk '{print $2}')
        hosts=$(echo "$line" | awk '{print $3}')
        print_info "$name ($ns): $hosts"
    done
else
    print_warning "Nenhum ingress encontrado"
fi
echo ""

# 7. Verificar DNS
print_section "DNS RESOLUTION"
DOMAINS=("argocd.dev.smartcity.local" "keycloak.dev.smartcity.local")
for domain in "${DOMAINS[@]}"; do
    if ping -c 1 -W 2 "$domain" &> /dev/null; then
        print_success "DNS $domain resolvendo"
    else
        print_error "DNS $domain não resolvendo"
        print_info "Verifique /etc/hosts: grep $domain /etc/hosts"
    fi
done
echo ""

# 8. Verificar conectividade HTTPS
print_section "HTTPS CONNECTIVITY"
if curl -k --max-time 5 --silent https://argocd.dev.smartcity.local > /dev/null; then
    print_success "ArgoCD UI acessível via HTTPS"
else
    print_warning "ArgoCD UI não acessível (pode estar inicializando)"
fi

if curl -k --max-time 5 --silent https://keycloak.dev.smartcity.local > /dev/null; then
    print_success "Keycloak acessível via HTTPS"
else
    print_warning "Keycloak não acessível (pode estar inicializando)"
fi
echo ""

# 9. Status geral
print_section "OVERALL STATUS"
TOTAL_PODS=$((ARGOCD_PODS + INFRA_PODS + INGRESS_PODS))
RUNNING_PODS=$((ARGOCD_RUNNING + INFRA_RUNNING + INGRESS_RUNNING))

if [ "$TOTAL_PODS" -eq "$RUNNING_PODS" ] && [ "$TOTAL_PODS" -gt 0 ]; then
    print_success "SISTEMA SAUDÁVEL: $RUNNING_PODS/$TOTAL_PODS pods rodando"
elif [ "$TOTAL_PODS" -gt 0 ]; then
    print_warning "SISTEMA COM PROBLEMAS: $RUNNING_PODS/$TOTAL_PODS pods rodando"
else
    print_error "SISTEMA NÃO IMPLANTADO: Nenhum pod encontrado"
fi
echo ""

# 10. Recomendações
print_section "RECOMMENDATIONS"
if [ "$TOTAL_PODS" -eq 0 ]; then
    echo "   💡 Execute o deploy completo: ./run.sh"
elif [ "$RUNNING_PODS" -lt "$TOTAL_PODS" ]; then
    echo "   💡 Verifique logs dos pods: kubectl get pods --all-namespaces"
    echo "   💡 Execute testes: ./test-deployment.sh"
else
    echo "   🎉 Sistema funcionando perfeitamente!"
    echo "   🌐 Acesse: https://argocd.dev.smartcity.local"
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Health check concluído!$(date)${NC}"
echo ""
