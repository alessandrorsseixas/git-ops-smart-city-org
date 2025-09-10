#!/bin/bash

# deploy.sh
# Script para implantar ou atualizar o PostgreSQL no cluster Kubernetes
# usando Helm.

# --- Configuração ---
# O 'set -e' garante que o script saia imediatamente se um comando falhar.
# O 'set -o pipefail' garante que falhas em pipelines sejam capturadas.
set -e
set -o pipefail

# --- Variáveis ---
# Centralizar as variáveis aqui facilita a manutenção.
readonly NAMESPACE="infrastructure"
readonly RELEASE_NAME="postgres-main"
readonly CHART_NAME="bitnami/postgresql"
readonly VALUES_FILE="postgres-deploy/postgres-minikube-values.yaml"
# Pinning the chart version is a critical best practice for production stability.
readonly CHART_VERSION="15.5.0" # Versão mais antiga que pode não ter problemas de autenticação

# --- Lógica do Script ---

# Passo 1: Adicionar e atualizar o repositório do Helm
echo "INFO: Adicionando e atualizando o repositório de charts da Bitnami..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
    
# Passo 2: Garantir que o namespace exista
# Usamos 'kubectl get' com '||' para criar o namespace apenas se ele não existir.
echo "INFO: Verificando se o namespace '$NAMESPACE' existe..."
kubectl get namespace "$NAMESPACE" > /dev/null 2>&1 || {
  echo "INFO: Namespace '$NAMESPACE' não encontrado. Criando..."
}
# Passo 3: Checar se o arquivo de values existe
if [ ! -f "$VALUES_FILE" ]; then
    echo "ERRO: Arquivo de configuração '$VALUES_FILE' não encontrado. Abortando."
    exit 1
fi

# Passo 4: Implantar ou atualizar o chart do PostgreSQL
# O comando 'helm upgrade --install' é idempotente. Ele instala se o release
# não existir e atualiza se ele já existir.
echo "INFO: Implantando/Atualizando o release '$RELEASE_NAME' no namespace '$NAMESPACE'..."
helm upgrade --install "$RELEASE_NAME" "$CHART_NAME" \
  --namespace "$NAMESPACE" \
  --version "$CHART_VERSION" \
  -f "$VALUES_FILE" \
  --wait # Opcional: espera os recursos do Kubernetes estarem no estado 'Ready'

echo "SUCCESS: Deploy do PostgreSQL concluído com sucesso."
echo "----------------------------------------------------"
echo "Para verificar o status, use:"
echo "kubectl get pods -n $NAMESPACE -l app.kubernetes.io/instance=$RELEASE_NAME"