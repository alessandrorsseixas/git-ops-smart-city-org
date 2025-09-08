#!/bin/bash

# test-deployment.sh
# Script para testar se o deployment está funcionando corretamente

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo "🧪 Testando deployment do Smart City GitOps..."
echo "=============================================="
echo ""

# Verificar Minikube
print_info "1. Verificando Minikube..."
if minikube status &> /dev/null; then
    print_success "Minikube está rodando"
    MINIKUBE_IP=$(minikube ip)
    print_info "IP do Minikube: $MINIKUBE_IP"
else
    print_error "Minikube não está rodando"
    exit 1
fi

# Verificar kubectl
print_info "2. Verificando kubectl..."
if kubectl cluster-info &> /dev/null; then
    print_success "kubectl conectado ao cluster"
else
    print_error "kubectl não consegue conectar ao cluster"
    exit 1
fi

# Verificar namespaces
print_info "3. Verificando namespaces..."
NAMESPACES=("smartcity" "argocd" "ingress-nginx")
for ns in "${NAMESPACES[@]}"; do
    if kubectl get namespace "$ns" &> /dev/null; then
        print_success "Namespace $ns existe"
    else
        print_warning "Namespace $ns não encontrado"
    fi
done

# Verificar pods do ArgoCD
print_info "4. Verificando pods do ArgoCD..."
ARGOCD_PODS=$(kubectl get pods -n argocd --no-headers 2>/dev/null | wc -l)
if [ "$ARGOCD_PODS" -gt 0 ]; then
    print_success "ArgoCD tem $ARGOCD_PODS pods rodando"
    kubectl get pods -n argocd --no-headers | while read -r line; do
        pod_name=$(echo "$line" | awk '{print $1}')
        pod_status=$(echo "$line" | awk '{print $3}')
        if [[ "$pod_status" == "Running" ]]; then
            print_success "Pod $pod_name: $pod_status"
        else
            print_warning "Pod $pod_name: $pod_status"
        fi
    done
else
    print_error "Nenhum pod do ArgoCD encontrado"
fi

# Verificar pods da infraestrutura
print_info "5. Verificando pods da infraestrutura..."
INFRA_PODS=$(kubectl get pods -n smartcity --no-headers 2>/dev/null | wc -l)
if [ "$INFRA_PODS" -gt 0 ]; then
    print_success "Infraestrutura tem $INFRA_PODS pods rodando"
    kubectl get pods -n smartcity --no-headers | while read -r line; do
        pod_name=$(echo "$line" | awk '{print $1}')
        pod_status=$(echo "$line" | awk '{print $3}')
        if [[ "$pod_status" == "Running" ]]; then
            print_success "Pod $pod_name: $pod_status"
        else
            print_warning "Pod $pod_name: $pod_status"
        fi
    done
else
    print_warning "Nenhum pod da infraestrutura encontrado"
fi

# Verificar serviços
print_info "6. Verificando serviços..."
SERVICES=("argocd-server" "keycloak-service" "postgres-service" "redis-service")
for svc in "${SERVICES[@]}"; do
    if kubectl get svc "$svc" -n smartcity &> /dev/null 2>&1 || kubectl get svc "$svc" -n argocd &> /dev/null 2>&1; then
        print_success "Serviço $svc existe"
    else
        print_warning "Serviço $svc não encontrado"
    fi
done

# Verificar ingress
print_info "7. Verificando ingress..."
INGRESS_COUNT=$(kubectl get ingress --all-namespaces --no-headers 2>/dev/null | wc -l)
if [ "$INGRESS_COUNT" -gt 0 ]; then
    print_success "$INGRESS_COUNT ingress configurado(s)"
    kubectl get ingress --all-namespaces
else
    print_warning "Nenhum ingress encontrado"
fi

# Verificar resolução DNS
print_info "8. Verificando resolução DNS..."
DOMAINS=("argocd.dev.smartcity.local" "keycloak.dev.smartcity.local")
for domain in "${DOMAINS[@]}"; do
    if ping -c 1 "$domain" &> /dev/null; then
        print_success "DNS $domain resolvendo corretamente"
    else
        print_error "DNS $domain não está resolvendo"
        print_info "Verifique se $domain está no /etc/hosts"
    fi
done

# Verificar conectividade HTTPS (opcional)
print_info "9. Verificando conectividade HTTPS..."
if curl -k --max-time 10 https://argocd.dev.smartcity.local &> /dev/null; then
    print_success "ArgoCD UI acessível via HTTPS"
else
    print_warning "ArgoCD UI não acessível via HTTPS (pode estar inicializando)"
fi

echo ""
print_success "Teste de deployment concluído!"
echo ""
echo "📊 Resumo:"
echo "   • Minikube: $(minikube status --format='{{.Host}}' 2>/dev/null || echo 'N/A')"
echo "   • ArgoCD Pods: $ARGOCD_PODS"
echo "   • Infra Pods: $INFRA_PODS"
echo "   • Ingress: $INGRESS_COUNT"
echo ""
echo "🌐 URLs para testar:"
echo "   • ArgoCD: https://argocd.dev.smartcity.local"
echo "   • Keycloak: https://keycloak.dev.smartcity.local"
echo ""
echo "🔧 Comandos úteis:"
echo "   • kubectl get pods --all-namespaces"
echo "   • kubectl logs -f deployment/argocd-server -n argocd"
echo "   • minikube dashboard"
