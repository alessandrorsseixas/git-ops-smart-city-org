#!/usr/bin/env bash
set -euo pipefail

# install-ingress.sh
# Habilita o addon ingress do Minikube e aguarda o controller estar pronto

usage(){ cat <<EOF
Usage: $(basename "$0") [-n namespace] [-h]

Habilita e configura o Ingress Controller no Minikube.
Este script verifica se o Minikube está rodando e reinicia se necessário.
EOF
}

INGRESS_NAMESPACE="ingress-nginx"
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n) NAMESPACE="$2"; shift 2;;
    -h) usage; exit 0;;
    *) break;;
  esac
done

echo "🌐 [FASE 2] Configurando Ingress Controller..."

# Verificar se minikube está disponível
if ! command -v minikube &> /dev/null; then
    echo "❌ Minikube não está instalado ou não está no PATH"
    exit 1
fi

# Verificar status do Minikube
echo "🔍 Verificando status do Minikube..."
if ! minikube status &> /dev/null; then
    echo "⚠️ Minikube não está rodando. Tentando iniciar..."
    
    # Tentar iniciar o Minikube com parâmetros padrão
    echo "🚀 Iniciando Minikube..."
    minikube start --driver=docker --cpus=2 --memory=4096mb --disk-size=20gb || {
        echo "❌ Falha ao iniciar Minikube"
        echo "💡 Tentativas de solução:"
        echo "   1. Verifique se o Docker está rodando: docker ps"
        echo "   2. Reinicie o Docker: sudo systemctl restart docker"
        echo "   3. Delete e recrie o cluster: minikube delete && minikube start"
        exit 1
    }
    
    echo "✅ Minikube iniciado com sucesso"
else
    echo "✅ Minikube está rodando"
fi

# Verificar se o addon ingress já está habilitado
echo "🔍 Verificando status do addon ingress..."
if minikube addons list | grep -q "ingress.*enabled"; then
    echo "✅ Addon ingress já está habilitado"
else
    echo "🔧 Habilitando addon ingress..."
    minikube addons enable ingress || {
        echo "❌ Falha ao habilitar ingress addon"
        echo "💡 Tentando solução alternativa..."
        
        # Tentar reiniciar minikube e habilitar novamente
        echo "🔄 Reiniciando Minikube..."
        minikube stop
        sleep 5
        minikube start
        sleep 10
        
        echo "🔧 Tentando habilitar ingress novamente..."
        minikube addons enable ingress || {
            echo "❌ Falha persistente ao habilitar ingress"
            echo "💡 Soluções manuais:"
            echo "   1. minikube delete && minikube start"
            echo "   2. Verificar recursos do sistema (CPU/Memória)"
            echo "   3. Verificar logs: minikube logs"
            exit 1
        }
    }
fi

echo "⏳ Aguardando Ingress Controller estar pronto..."

# Aguardar namespace do ingress ser criado
timeout=60
counter=0
while [ $counter -lt $timeout ]; do
    if kubectl get namespace $INGRESS_NAMESPACE &> /dev/null; then
        echo "✅ Namespace $INGRESS_NAMESPACE criado"
        break
    fi
    echo "⏳ Aguardando namespace $INGRESS_NAMESPACE... ($counter/$timeout)"
    sleep 2
    counter=$((counter + 2))
done

if [ $counter -ge $timeout ]; then
    echo "❌ Timeout aguardando namespace $INGRESS_NAMESPACE"
    exit 1
fi

# Aguardar deployment do ingress controller
echo "⏳ Aguardando deployment do Ingress Controller..."
kubectl -n $INGRESS_NAMESPACE rollout status deployment/ingress-nginx-controller --timeout=300s || {
    echo "❌ Timeout aguardando Ingress Controller"
    echo "🔍 Status atual:"
    kubectl -n $INGRESS_NAMESPACE get pods
    echo "💡 Tentando aguardar mais tempo..."
    sleep 30
    kubectl -n $INGRESS_NAMESPACE rollout status deployment/ingress-nginx-controller --timeout=120s || {
        echo "❌ Ingress Controller não ficou pronto"
        echo "🔍 Logs do controller:"
        kubectl -n $INGRESS_NAMESPACE logs -l app.kubernetes.io/name=ingress-nginx --tail=50
        exit 1
    }
}

# Verificar se o controller está respondendo
echo "🔍 Verificando se Ingress Controller está respondendo..."
kubectl -n $INGRESS_NAMESPACE get pods -l app.kubernetes.io/name=ingress-nginx

# Aguardar um pouco mais para estabilizar
echo "⏳ Aguardando estabilização do Ingress Controller..."
sleep 15

echo "✅ Ingress Controller configurado e pronto!"
echo ""
echo "📋 Informações do Ingress:"
kubectl -n $INGRESS_NAMESPACE get svc
echo ""
echo "💡 O Ingress Controller está pronto para receber configurações de Ingress"
