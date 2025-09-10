#!/bin/bash

# deploy-redis.sh
# Script para implantar ou atualizar o Redis otimizado para Minikube.

set -e
set -o pipefail

# --- Variáveis ---
readonly NAMESPACE="infrastructure" # Usaremos o mesmo namespace 'dev' para co-localizar com o postgres de estudo
readonly RELEASE_NAME="redis-study"
readonly CHART_NAME="bitnami/redis"
readonly VALUES_FILE="redis-values-minikube.yaml"
# Pinning de versão para deploy consistente
readonly CHART_VERSION="22.0.7"

# --- Lógica do Script ---

# Passo 1: Adicionar o repositório da Bitnami (caso ainda não tenha sido adicionado)
echo "INFO: Adicionando e atualizando o repositório de charts da Bitnami..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Passo 2: Garantir que o namespace exista
echo "INFO: Verificando se o namespace '$NAMESPACE' existe..."
kubectl get namespace "$NAMESPACE" > /dev/null 2>&1 || {
  echo "INFO: Namespace '$NAMESPACE' não encontrado. Criando..."
  kubectl create namespace "$NAMESPACE"
}

# Passo 3: Checar se o arquivo de values existe
if [ ! -f "$VALUES_FILE" ]; then
    echo "ERRO: Arquivo de configuração '$VALUES_FILE' não encontrado. Abortando."
    exit 1
fi

# Passo 4: Implantar ou atualizar o chart do Redis
echo "INFO: Implantando/Atualizando o release '$RELEASE_NAME' no namespace '$NAMESPACE'..."
helm upgrade --install "$RELEASE_NAME" "$CHART_NAME" \
  --namespace "$NAMESPACE" \
  --version "$CHART_VERSION" \
  -f "$VALUES_FILE" \
  --wait

echo "SUCCESS: Deploy do Redis concluído com sucesso."
echo "----------------------------------------------------"
echo "Para verificar o status, use:"
echo "kubectl get pods -n $NAMESPACE -l app.kubernetes.io/instance=$RELEASE_NAME"