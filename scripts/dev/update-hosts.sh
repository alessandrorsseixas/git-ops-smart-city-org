#!/bin/bash

# update-hosts.sh
# Script para atualizar /etc/hosts com entradas necessárias para Smart City GitOps

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
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

# Arquivo hosts
HOSTS_FILE="/etc/hosts"
BACKUP_FILE="/etc/hosts.backup.smartcity"

# Obter IP do Minikube (executar sem sudo)
print_info "Obtendo IP do Minikube..."
if ! command -v minikube &> /dev/null; then
    print_error "Minikube não está instalado ou não está no PATH"
    exit 1
fi

# Se não está rodando como root, tentar obter IP e depois pedir sudo
if [[ $EUID -ne 0 ]]; then
    print_info "Obtendo IP do Minikube primeiro..."
    if ! MINIKUBE_IP=$(minikube ip 2>/dev/null); then
        print_error "Não foi possível obter o IP do Minikube"
        echo "💡 Verifique se o Minikube está rodando: minikube status"
        echo "💡 Se necessário, inicie o Minikube: minikube start"
        exit 1
    fi
    print_success "IP do Minikube: $MINIKUBE_IP"
    print_info "Agora executando com sudo para modificar /etc/hosts..."
    exec sudo MINIKUBE_IP="$MINIKUBE_IP" "$0" "$@"
fi

print_success "IP do Minikube: $MINIKUBE_IP"

# Criar backup se não existir
if [[ ! -f "$BACKUP_FILE" ]]; then
    print_info "Criando backup do arquivo hosts..."
    cp "$HOSTS_FILE" "$BACKUP_FILE"
    print_success "Backup criado: $BACKUP_FILE"
fi

# Entradas a serem adicionadas
HOST_ENTRIES=(
    "$MINIKUBE_IP argocd.dev.smartcity.local"
    "$MINIKUBE_IP argocd-grpc.dev.smartcity.local"
    "$MINIKUBE_IP keycloak.dev.smartcity.local"
    "$MINIKUBE_IP smartcity.local"
    "$MINIKUBE_IP rancher.dev.smartcity.local"
)

# Função para verificar se entrada já existe
entry_exists() {
    local entry="$1"
    grep -q "^$entry$" "$HOSTS_FILE"
}

# Função para adicionar entrada
add_entry() {
    local entry="$1"
    echo "$entry" >> "$HOSTS_FILE"
}

# Verificar e adicionar entradas
print_info "Verificando entradas no /etc/hosts..."
ADDED_COUNT=0

for entry in "${HOST_ENTRIES[@]}"; do
    if entry_exists "$entry"; then
        print_info "Entrada já existe: $entry"
    else
        print_info "Adicionando entrada: $entry"
        add_entry "$entry"
        ((ADDED_COUNT++))
    fi
done

if [[ $ADDED_COUNT -gt 0 ]]; then
    print_success "$ADDED_COUNT entrada(s) adicionada(s) ao /etc/hosts"
else
    print_success "Todas as entradas já existem no /etc/hosts"
fi

# Verificar se as entradas foram adicionadas corretamente
print_info "Verificando entradas adicionadas..."
echo ""
echo "📋 Entradas atuais no /etc/hosts:"
for entry in "${HOST_ENTRIES[@]}"; do
    if entry_exists "$entry"; then
        echo -e "${GREEN}   ✅ $entry${NC}"
    else
        echo -e "${RED}   ❌ $entry${NC}"
    fi
done

echo ""
print_success "Configuração do /etc/hosts concluída!"
echo ""
echo "🌐 URLs disponíveis:"
echo "   • ArgoCD UI: https://argocd.dev.smartcity.local"
echo "   • ArgoCD GRPC: https://argocd-grpc.dev.smartcity.local"
echo "   • Keycloak: https://keycloak.dev.smartcity.local"
echo ""
echo "🔍 Para verificar:"
echo "   • ping argocd.dev.smartcity.local"
echo "   • curl -k https://argocd.dev.smartcity.local"
echo ""
echo "📝 Para reverter as mudanças:"
echo "   sudo cp $BACKUP_FILE $HOSTS_FILE"
