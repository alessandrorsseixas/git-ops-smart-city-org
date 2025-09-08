#!/bin/bash

# init-minikube.sh
# Script rápido para inicializar o Minikube com parâmetros padronizados

set -e

echo "🚀 Inicializando Minikube para Smart City GitOps..."
echo ""

# Parâmetros padrão
DRIVER="docker"
CPUS="2"
MEMORY="4096mb"
DISK_SIZE="20gb"

# Verificar se minikube está instalado
if ! command -v minikube &> /dev/null; then
    echo "❌ Minikube não está instalado"
    echo "💡 Instale com: curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && sudo install minikube-linux-amd64 /usr/local/bin/minikube"
    exit 1
fi

# Verificar se Docker está rodando
if ! docker ps &> /dev/null; then
    echo "❌ Docker não está rodando ou não está acessível"
    echo "💡 Inicie o Docker ou adicione seu usuário ao grupo docker"
    exit 1
fi

# Limpar cluster existente se houver problemas
if minikube status &> /dev/null; then
    echo "✅ Minikube já está rodando"
    minikube status
else
    echo "🔄 Minikube não está rodando. Verificando estado..."
    
    # Se há algum problema, limpar e recriar
    echo "🧹 Limpando estado anterior..."
    minikube delete 2>/dev/null || echo "⚠️ Nenhum cluster para remover"
    
    echo "🚀 Iniciando novo cluster Minikube..."
    echo "   Configuração: --driver=$DRIVER --cpus=$CPUS --memory=$MEMORY --disk-size=$DISK_SIZE"
    
    minikube start --driver=$DRIVER --cpus=$CPUS --memory=$MEMORY --disk-size=$DISK_SIZE || {
        echo "❌ Falha ao iniciar Minikube"
        echo ""
        echo "💡 Possíveis soluções:"
        echo "   1. Verificar se Docker está funcionando: docker ps"
        echo "   2. Reiniciar Docker: sudo systemctl restart docker"
        echo "   3. Verificar recursos disponíveis: free -h"
        echo "   4. Tentar com menos recursos: minikube start --cpus=1 --memory=2048mb"
        exit 1
    }
fi

echo ""
echo "✅ Minikube inicializado com sucesso!"
echo ""
echo "📊 Informações do cluster:"
echo "   Status: $(minikube status --format='{{.Host}}')"
echo "   IP: $(minikube ip)"
echo "   Docker Engine: $(minikube status --format='{{.Kubelet}}')"
echo ""
echo "🔧 Próximos passos:"
echo "   - Configure kubectl: kubectl config use-context minikube"
echo "   - Habilite addons: minikube addons enable ingress"
echo "   - Execute deploy: ./deploy/deploy-all.sh"
echo ""
