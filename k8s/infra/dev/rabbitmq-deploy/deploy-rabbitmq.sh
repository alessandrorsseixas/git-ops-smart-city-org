#!/bin/bash

# deploy-rabbitmq.sh
# Script para implantar ou atualizar o RabbitMQ otimizado para Minikube.

set -e
set -o pipefail

# --- Variáveis ---
readonly NAMESPACE="infrastructure" # Implantando no mesmo namespace de infraestrutura
readonly RELEASE_NAME="rabbitmq-study"
readonly CHART_NAME="bitnami/rabbitmq"
readonly VALUES_FILE="rabbitmq-values-minikube.yaml"
# Pinning de versão para deploy consistente e previsível
readonly CHART_VERSION="14.4.0"

# --- Lógica do Script ---

# Passo 1: Adicionar e atualizar o repositório do Helm da Bitnami
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

# Passo 4: Implantar ou atualizar o chart do RabbitMQ
echo "INFO: Implantando/Atualizando o release '$RELEASE_NAME' no namespace '$NAMESPACE'..."
helm upgrade --install "$RELEASE_NAME" "$CHART_NAME" \
  --namespace "$NAMESPACE" \
  --version "$CHART_VERSION" \
  -f "$VALUES_FILE" \
  --wait

echo "SUCCESS: Deploy do RabbitMQ concluído com sucesso."
echo "----------------------------------------------------"
echo "Para verificar o status, use:"
echo "kubectl get pods -n $NAMESPACE -l app.kubernetes.io/instance=$RELEASE_NAME"