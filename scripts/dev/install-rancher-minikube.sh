#!/bin/bash
set -euo pipefail

# ====================================================================================
# Arquivo: install-rancher-linux-v2.sh
# Descrição: Script para provisionar um ambiente Rancher localmente usando
#            Minikube e Helm. Otimizado para Linux, incorporando lições de
#            depuração de resolução de DNS e ciclo de vida de segredos.
# Arquiteto: Alessandro Seixas
# ====================================================================================

# ====================================================================================
# Variáveis de Configuração Estratégica
# ====================================================================================
# Domínio de acesso ao Rancher. Usamos .local para evitar conflitos com o TLD
# protegido .localhost e garantir a correta resolução via /etc/hosts.
INGRESS_HOST="rancher.local"
# Namespace onde os componentes core do Rancher serão instalados.
NAMESPACE="cattle-system"
# Versão do Rancher. Fixar a versão garante a consistência entre ambientes.
RANCHER_VERSION="v2.7.3"

# --- Configurações técnicas ---
RANCHER_HELM_RELEASE="rancher"
RANCHER_HELM_CHART="rancher-latest/rancher"
INGRESS_NAMESPACE="ingress-nginx"
INGRESS_CLASS_NAME="nginx"
TLS_SECRET_NAME="tls-rancher-ingress"
CERT_FILE="./tls.crt"
KEY_FILE="./tls.key"

# Path to infra dev services (will be applied)
WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
INFRA_DEV_DIR="$WORKSPACE_ROOT/infra/dev"

# CLI options
RECREATE_ENV=false

# ====================================================================================
# Funções de Validação e Pré-requisitos
# ====================================================================================

# Função para verificar se um comando CLI essencial existe no PATH.
function check_command() {
  command -v "$1" >/dev/null 2>&1 || { echo >&2 "ARQUITETURA-ERRO: O comando '$1' é um pré-requisito e não foi encontrado. Abortando."; exit 1; }
}

# Função para validar a ordem de resolução de nomes, um ponto crítico de falha.
function check_nsswitch() {
  # A ordem correta deve ser 'files' antes de 'dns' para priorizar /etc/hosts.
  if ! grep -q -E "^hosts:\s+files" /etc/nsswitch.conf; then
    echo "ARQUITETURA-AVISO: A configuração em /etc/nsswitch.conf não prioriza 'files'."
    echo "Isso pode fazer com que a entrada em /etc/hosts para '$INGRESS_HOST' seja ignorada."
    echo "Configuração atual:"
    grep "^hosts:" /etc/nsswitch.conf
    echo "Recomendado: 'hosts: files dns'"
    # Não aborta, mas alerta o usuário sobre um risco potencial.
  fi
}

# Check node allocatable resources and optionally suggest increasing minikube
function check_node_resources_or_prompt() {
  NODE_NAME=$(kubectl get nodes -o name | head -n1 || true)
  if [[ -z "$NODE_NAME" ]]; then
    echo "No nodes found in cluster. Is kubectl configured?"
    exit 1
  fi
  CPU_ALLOC=$(kubectl get "$NODE_NAME" -o jsonpath='{.status.allocatable.cpu}')
  MEM_ALLOC=$(kubectl get "$NODE_NAME" -o jsonpath='{.status.allocatable.memory}')

  # normalize
  if [[ "$CPU_ALLOC" == *m ]]; then
    CPU_M=${CPU_ALLOC%m}
  else
    CPU_M=$(( CPU_ALLOC * 1000 ))
  fi

  if [[ "$MEM_ALLOC" == *Ki ]]; then
    MEM_MI=$(( ${MEM_ALLOC%Ki} / 1024 ))
  elif [[ "$MEM_ALLOC" == *Mi ]]; then
    MEM_MI=${MEM_ALLOC%Mi}
  elif [[ "$MEM_ALLOC" == *Gi ]]; then
    MEM_MI=$(( ${MEM_ALLOC%Gi} * 1024 ))
  else
    MEM_MI=0
  fi

  echo "Cluster allocatable: CPU=${CPU_M}m, MEM=${MEM_MI}Mi"
  if (( CPU_M < 2000 )) || (( MEM_MI < 4096 )); then
    echo "Recursos do cluster abaixo do recomendado (2 CPU / 4Gi)."
    read -r -p "Deseja reiniciar o Minikube com 4 CPU e 8Gi de RAM agora? (recomendado para Rancher) (y/N): " resp
    if [[ "$resp" =~ ^[Yy]$ ]]; then
      echo "Reiniciando Minikube com recursos aumentados..."
      minikube stop || true
      minikube delete --all --purge || true
      minikube start --driver=docker --cpus=4 --memory=8192
      echo "Minikube reiniciado. Aguarde alguns segundos para o cluster estabilizar."
    else
      echo "Continuando sem alterar recursos (pode falhar se insuficiente)."
    fi
  fi
}

# Apply infra/dev manifests (services/ingress helpers)
function apply_infra_dev() {
  if [[ -d "$INFRA_DEV_DIR" ]]; then
    echo "Aplicando infra dev (infra/dev)..."
    kubectl apply -k "$INFRA_DEV_DIR"
  else
    echo "Pasta infra/dev não encontrada: $INFRA_DEV_DIR"
  fi
}

# Ensure /etc/hosts entry for INGRESS_HOST, ask for confirmation and use sudo to append
function ensure_hosts_entry() {
  MINIKUBE_IP=$(minikube ip 2>/dev/null || true)
  if [[ -z "$MINIKUBE_IP" ]]; then
    echo "Não foi possível obter IP do Minikube. Pule a escrita em /etc/hosts e use instrução manual no final.";
    return
  fi
  if grep -q "${INGRESS_HOST}" /etc/hosts; then
    echo "/etc/hosts já contém ${INGRESS_HOST}. Verifique entrada existente.";
    return
  fi
  echo "Irei adicionar a entrada no /etc/hosts: ${MINIKUBE_IP} ${INGRESS_HOST}"
  read -r -p "Permito que o script escreva em /etc/hosts usando sudo? (y/N): " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    echo "Adicionando entrada em /etc/hosts..."
    echo "${MINIKUBE_IP} ${INGRESS_HOST}" | sudo tee -a /etc/hosts >/dev/null
    echo "Entrada adicionada."
  else
    echo "Você pode adicionar manualmente: sudo sh -c 'echo \"${MINIKUBE_IP} ${INGRESS_HOST}\" >> /etc/hosts'"
  fi
}

# Parse CLI args for recreate flag
for arg in "${@}"; do
  case "$arg" in
    --recreate) RECREATE_ENV=true ;;
  esac
done

# ====================================================================================
# Orquestração da Instalação (fluxo principal)
# ====================================================================================

echo "### [FASE 0] Validando pré-requisitos da arquitetura..."
check_command kubectl
check_command helm
check_command minikube
check_command openssl
check_nsswitch
echo "Pré-requisitos validados."

# --- Passo 1: Provisionamento do Cluster Kubernetes (Minikube) ---
echo -e "\n### [FASE 1] Verificando e, se necessário, inicializando o cluster Minikube..."
if ! minikube status >/dev/null 2>&1; then
  echo "Provisionando novo cluster Minikube com 4GB de RAM e 2 vCPUs..."
  minikube start --driver=docker --memory=4096 --cpus=2
else
  echo "Cluster Minikube já está em execução."
fi

# Check node resources and optionally resize with confirmation
check_node_resources_or_prompt

# --- Passo 1.5: Aplicar infra/dev para expor ingress (Ingress Controller já ativado pelo addon) ---
apply_infra_dev

# Optionally recreate environment (delete namespace) to get a clean Rancher install
if [[ "$RECREATE_ENV" == true ]]; then
  echo "Removendo namespace $NAMESPACE para recriar ambiente..."
  kubectl delete namespace "$NAMESPACE" --ignore-not-found=true || true
  # allow deletion to finish
  sleep 5
fi

# --- Passo 2: Configuração do Ingress Controller (Nginx) ---
echo -e "\n### [FASE 2] Habilitando e aguardando o Ingress Controller..."
minikube addons enable ingress
echo "Aguardando o deployment 'ingress-nginx-controller' atingir o estado 'pronto'..."
kubectl -n $INGRESS_NAMESPACE rollout status deployment/ingress-nginx-controller --timeout=5m

# --- Passo 3: Configuração do Repositório Helm do Rancher ---
echo -e "\n### [FASE 3] Adicionando o repositório Helm do Rancher..."
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update

# --- Passo 4: Criação do Namespace do Rancher ---
echo -e "\n### [FASE 4] Garantindo a existência do namespace '$NAMESPACE'..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# --- Passo 5: Geração e Gestão do Certificado TLS ---
echo -e "\n### [FASE 5] Gerenciando o certificado TLS para o Ingress..."
if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
  echo "Gerando novo certificado TLS autoassinado para o host '$INGRESS_HOST'..."
  openssl req -x509 -newkey rsa:4096 -nodes \
    -keyout "$KEY_FILE" \
    -out "$CERT_FILE" \
    -days 365 \
    -subj "/CN=$INGRESS_HOST"
else
  echo "Certificado TLS ('$CERT_FILE', '$KEY_FILE') já existe."
fi

# --- Passo 6: Criação do Segredo TLS no Kubernetes ---
echo -e "\n### [FASE 6] Criando/Atualizando o segredo Kubernetes para o TLS..."
kubectl -n $NAMESPACE delete secret $TLS_SECRET_NAME --ignore-not-found
kubectl -n $NAMESPACE create secret tls $TLS_SECRET_NAME \
  --cert="$CERT_FILE" \
  --key="$KEY_FILE"

# --- Passo 7: Instalação do Rancher via Helm ---
echo -e "\n### [FASE 7] Realizando o deploy do Rancher (versão $RANCHER_VERSION) para o host '$INGRESS_HOST'..."
helm upgrade --install $RANCHER_HELM_RELEASE $RANCHER_HELM_CHART \
  --namespace $NAMESPACE \
  --set hostname=$INGRESS_HOST \
  --set rancherImageTag=$RANCHER_VERSION \
  --set ingress.tls.source=secret \
  --set ingress.ingressClassName=$INGRESS_CLASS_NAME

# --- Passo 8: Aguardar o Rollout do Rancher ---
echo -e "\n### [FASE 8] Aguardando o deployment do Rancher ser concluído..."
kubectl -n $NAMESPACE rollout status deployment/rancher --timeout=10m

# --- Passo 9: Extração de Credenciais e Instruções de Acesso ---
echo -e "\n### [FASE 9] Instalação concluída. Preparando instruções de acesso..."

MINIKUBE_IP=$(minikube ip)

echo -e "\n========================= ACESSO AO RANCHER ========================="
echo "O Rancher foi instalado com sucesso. Siga os passos abaixo:"
echo ""
echo "1. Configure a resolução de nome local para o Rancher:"
if grep -q "$INGRESS_HOST" /etc/hosts; then
  echo "   -> A entrada para '$INGRESS_HOST' já existe em /etc/hosts. Verifique se o IP ($MINIKUBE_IP) está correto."
else
  echo "   -> Execute o comando abaixo para mapear '$INGRESS_HOST' ao IP do Minikube:"
  echo -e "\n      echo \"$MINIKUBE_IP $INGRESS_HOST\" | sudo tee -a /etc/hosts\n"
fi

echo "2. Acesse a UI do Rancher em seu navegador:"
echo -e "   URL: https://$INGRESS_HOST"
echo ""
echo "3. Obtenha a senha de administrador:"

# Aguarda o pod do Rancher estar pronto antes de tentar obter a senha
echo "   -> Aguardando pod do Rancher estar pronto..."
kubectl wait --namespace $NAMESPACE --for=condition=ready pod -l app=rancher --timeout=300s

# Tenta obter a senha de bootstrap com métodos alternativos
BOOTSTRAP_PASSWORD=""

# Método 1: Verificar se existe o secret bootstrap-secret
if kubectl get secret --namespace $NAMESPACE bootstrap-secret &>/dev/null; then
  BOOTSTRAP_PASSWORD=$(kubectl get secret --namespace $NAMESPACE bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}' 2>/dev/null || echo "")
fi

# Método 2: Se não encontrou, tenta buscar nos logs do pod
if [ -z "$BOOTSTRAP_PASSWORD" ]; then
  echo "   -> Buscando senha nos logs do Rancher..."
  POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=rancher -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
  if [ -n "$POD_NAME" ]; then
    # Busca por padrões de senha de bootstrap nos logs
    BOOTSTRAP_PASSWORD=$(kubectl logs -n $NAMESPACE $POD_NAME 2>/dev/null | grep -i "bootstrap password" | tail -1 | awk '{print $NF}' || echo "")
    if [ -z "$BOOTSTRAP_PASSWORD" ]; then
      BOOTSTRAP_PASSWORD=$(kubectl logs -n $NAMESPACE $POD_NAME 2>/dev/null | grep -E "password.*[a-zA-Z0-9]{8,}" | tail -1 | grep -oE "[a-zA-Z0-9]{8,}" | tail -1 || echo "")
    fi
  fi
fi

# Método 3: Gerar nova senha usando reset-password
if [ -z "$BOOTSTRAP_PASSWORD" ] && [ -n "$POD_NAME" ]; then
  echo "   -> Gerando nova senha de bootstrap..."
  BOOTSTRAP_PASSWORD=$(kubectl exec -n $NAMESPACE $POD_NAME -- reset-password 2>/dev/null | grep -E "New password:" | awk '{print $NF}' || echo "")
fi

# Exibe resultado
if [ -n "$BOOTSTRAP_PASSWORD" ]; then
  echo "   -> Senha de bootstrap encontrada:"
  echo "      Usuário: admin"
  echo "      Senha: $BOOTSTRAP_PASSWORD"
else
  echo "   -> Não foi possível obter a senha automaticamente."
  echo "      Execute manualmente para obter/redefinir a senha:"
  if [ -n "$POD_NAME" ]; then
    echo -e "\n      kubectl exec -n $NAMESPACE $POD_NAME -- reset-password"
  else
    echo -e "\n      kubectl get pods -n $NAMESPACE -l app=rancher"
    echo "      kubectl exec -n $NAMESPACE <POD_NAME> -- reset-password"
  fi
  echo -e "\n      OU verifique os logs:"
  echo "      kubectl logs -n $NAMESPACE -l app=rancher | grep -i password"
fi
echo "======================================================================="
