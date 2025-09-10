#!/bin/bash

# deploy-prometheus.sh
# Script para implantar ou atualizar o stack Prometheus otimizado para Minikube.

set -e
set -o pipefail

# --- Variáveis ---
readonly NAMESPACE="monitoring"
readonly RELEASE_NAME="prometheus-stack"
# O chart 'kube-prometheus-stack' vive em um repositório diferente do de postgres.
readonly CHART_NAME="prometheus-community/kube-prometheus-stack"
readonly VALUES_FILE="prometheus-values-minikube.yaml"
# Pinning de versão para garantir consistência.
readonly CHART_VERSION="27.37.0"

# --- Lógica do Script ---

# Passo 1: Adicionar o repositório da comunidade Prometheus
echo "INFO: Adicionando e atualizando o repositório de charts da Prometheus Community..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
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

# Passo 4: Implantar ou atualizar o chart do Prometheus
echo "INFO: Implantando/Atualizando o release '$RELEASE_NAME' no namespace '$NAMESPACE'..."
helm upgrade --install "$RELEASE_NAME" "$CHART_NAME" \
  --namespace "$NAMESPACE" \
  --version "$CHART_VERSION" \
  -f "$VALUES_FILE" \
  --wait

echo "SUCCESS: Deploy do Prometheus Stack concluído com sucesso."
echo "----------------------------------------------------"
echo "O stack pode levar alguns minutos para ficar totalmente funcional."
echo "Use 'kubectl get pods -n $NAMESPACE' para verificar o status."