# Smart City Infrastructure - Development Environment

Este documento descreve a infraestrutura de desenvolvimento do Smart City, organizada com Kustomize e Helm para facilitar o deployment no Minikube.

## 🎯 Script Master de Deployment

### `deploy-all-infrastructure.sh`

O script principal para deployment completo da infraestrutura. **Recomendado para uso geral**.

#### Funcionalidades
- ✅ **Verificação automática de pré-requisitos** (kubectl, helm, minikube)
- ✅ **Criação automática do namespace** `infrastructure`
- ✅ **Deployment sequencial** de todos os componentes
- ✅ **Configuração automática do /etc/hosts** (com privilégios de root)
- ✅ **Verificação final** do status de todos os componentes
- ✅ **Informações completas de acesso** aos serviços
- ✅ **Tratamento de erros** e logs coloridos
- ✅ **Cálculo de tempo** total de deployment

#### Como usar
```bash
# Deployment completo (recomendado)
./deploy-all-infrastructure.sh

# Com configuração automática do /etc/hosts
sudo ./deploy-all-infrastructure.sh
```

#### O que o script faz
1. **Verifica pré-requisitos**: kubectl, helm, minikube
2. **Cria namespace**: `infrastructure`
3. **Deploy do Ingress**: NGINX Ingress Controller
4. **Deploy dos bancos**: PostgreSQL e Redis
5. **Deploy da mensageria**: RabbitMQ
6. **Deploy do monitoramento**: Prometheus
7. **Deploy do GitOps**: ArgoCD
8. **Configura /etc/hosts**: Domínios locais automaticamente
9. **Verifica status**: Todos os pods e serviços
10. **Mostra informações de acesso**: URLs e portas

#### Configuração automática do /etc/hosts
O script detecta automaticamente o IP do Minikube e configura os domínios no `/etc/hosts`:

```bash
# Exemplo de configuração automática
192.168.58.2 postgres.dev.smartcity.local
192.168.58.2 redis.dev.smartcity.local
192.168.58.2 rabbitmq.dev.smartcity.local
192.168.58.2 prometheus.dev.smartcity.local
192.168.58.2 argocd.dev.smartcity.local
```

#### Tratamento de privilégios
- **Sem sudo**: Mostra instruções para configuração manual
- **Com sudo**: Configura automaticamente o `/etc/hosts`
- **Detecção inteligente**: Funciona mesmo quando executado como root

## 📁 Estrutura de Diretórios

```
k8s/infra/dev/
├── README.md                    # Este arquivo
├── infrastructure-namespace.yaml # Definição do namespace
├── infrastructure-ingress.yaml   # Ingress para exposição dos serviços
├── infrastructure-tcp-services.yaml # Configurações TCP para serviços não-HTTP
├── deploy-infrastructure-ingress.sh # Script de deployment do Ingress
├── ingress-deploy/               # Diretório específico do Ingress
│   └── README.md
├── postgres-deploy/            # PostgreSQL deployment
│   ├── README.md
│   ├── deploy.sh
│   └── postgres-minikube-values.yaml
├── rabbitmq-deploy/            # RabbitMQ deployment
│   ├── README.md
│   ├── deploy-rabbitmq.sh
│   └── rabbitmq-values-minikube.yaml
├── redis-deploy/               # Redis deployment
│   ├── README.md
│   ├── deploy-redis.sh
│   └── redis-values-minikube.yaml
├── prometheus-deploy/          # Prometheus deployment
│   ├── README.md
│   ├── deploy-prometheus.sh
│   └── prometheus-values-minikube.yaml
└── argo-cd-deploy/             # ArgoCD deployment
    ├── README.md
    ├── deploy-argo-cd.sh
    └── argo-cd-values-minikube.yaml
```

## 🚀 Componentes da Infraestrutura

### Banco de Dados
- **PostgreSQL**: Banco de dados principal da aplicação
- **Redis**: Cache e armazenamento de sessões

### Mensageria
- **RabbitMQ**: Sistema de mensageria assíncrona

### Monitoramento
- **Prometheus**: Coleta de métricas e alertas

### GitOps
- **ArgoCD**: Continuous Delivery para Kubernetes

## 🌐 Ingress e Exposição de Serviços

Todos os serviços são expostos através de domínios padronizados usando o NGINX Ingress Controller:

### Domínios Configurados
- **PostgreSQL**: `postgres.dev.smartcity.local:5432`
- **RabbitMQ**: `rabbitmq.dev.smartcity.local:15672`
- **Redis**: `redis.dev.smartcity.local:6379`
- **Prometheus**: `prometheus.dev.smartcity.local:9090`
- **ArgoCD**: `argocd.dev.smartcity.local:8080`
- **Grafana**: `grafana.dev.smartcity.local:80`
- **Keycloak**: `keycloak.dev.smartcity.local:8080`
- **MongoDB**: `mongodb.dev.smartcity.local:27017`
- **Smart City App**: `app.dev.smartcity.local:8080`
- **Smart City API**: `api.dev.smartcity.local:8080`

### Deployment do Ingress
```bash
# Deploy do Ingress Controller e regras
./deploy-infrastructure-ingress.sh

# Ou manualmente
kubectl apply -f infrastructure-ingress.yaml
kubectl apply -f infrastructure-tcp-services.yaml
```

### Configuração Local (/etc/hosts)
```bash
# Adicionar ao /etc/hosts (substitua pelo IP do Minikube)
192.168.49.2 postgres.dev.smartcity.local
192.168.49.2 rabbitmq.dev.smartcity.local
192.168.49.2 redis.dev.smartcity.local
# ... outros domínios
```

## 🛠️ Pré-requisitos

- Minikube instalado e em execução
- kubectl configurado
- Helm 3.x instalado
- Git

## 📋 Namespace

Todos os componentes são deployados no namespace `infrastructure`:

```bash
kubectl create namespace infrastructure
```

## 🚀 Deployment Rápido

### Método 1: Script Master (Recomendado)

```bash
# Deployment completo e automatizado
./deploy-all-infrastructure.sh

# Ou com configuração automática do /etc/hosts
sudo ./deploy-all-infrastructure.sh
```

**Vantagens:**
- ✅ Tudo automatizado em sequência
- ✅ Verificações de pré-requisitos
- ✅ Configuração automática do /etc/hosts
- ✅ Logs coloridos e informativos
- ✅ Tratamento de erros
- ✅ Informações completas de acesso

### Método 2: Deployment Individual

Para desenvolvimento ou troubleshooting, faça o deployment individual de cada componente:

```bash
# 1. Ingress Controller (sempre primeiro)
./deploy-infrastructure-ingress.sh

# 2. PostgreSQL
cd postgres-deploy && ./deploy.sh

# 3. Redis
cd ../redis-deploy && ./deploy-redis.sh

# 4. RabbitMQ
cd ../rabbitmq-deploy && ./deploy-rabbitmq.sh

# 5. Prometheus
cd ../prometheus-deploy && ./deploy-prometheus.sh

# 6. ArgoCD
cd ../argo-cd-deploy && ./deploy-argo-cd.sh
```

**Quando usar:** Desenvolvimento, troubleshooting ou quando precisar de controle fino sobre cada componente.

## 🔍 Verificação do Deployment

```bash
# Verificar pods
kubectl get pods -n infrastructure

# Verificar services
kubectl get svc -n infrastructure

# Verificar ingress
kubectl get ingress -n infrastructure
```

## 📊 Acesso aos Serviços

### PostgreSQL
```bash
# Port forward
kubectl port-forward -n infrastructure svc/postgres-external 5432:5432

# Conectar
psql -h localhost -p 5432 -U smartcity -d smartcity
```

### RabbitMQ Management
```bash
# Port forward
kubectl port-forward -n infrastructure svc/rabbitmq-management 15672:15672

# Acessar: http://localhost:15672
# User: admin
# Password: admin123
```

### Redis
```bash
# Port forward
kubectl port-forward -n infrastructure svc/redis 6379:6379

# Conectar
redis-cli -h localhost -p 6379
```

## 🧹 Limpeza

Para remover toda a infraestrutura:

```bash
# Remover todos os componentes
kubectl delete namespace infrastructure

# Ou remover individualmente
helm uninstall postgres -n infrastructure
helm uninstall redis -n infrastructure
helm uninstall rabbitmq -n infrastructure
helm uninstall prometheus -n infrastructure
helm uninstall argocd -n infrastructure
```

## 📝 Notas Importantes

- Todos os deployments estão configurados para Minikube
- As senhas padrão estão definidas nos arquivos values
- Os serviços externos usam ClusterIP para compatibilidade com Minikube
- Use port-forwarding para acessar serviços externos

## 🔧 Desenvolvimento Local

Para desenvolvimento local, use os scripts de deployment em cada diretório específico. Cada componente tem seu próprio README com instruções detalhadas.

## 📚 Documentação

Cada diretório de deployment contém documentação detalhada:

- **[PostgreSQL](postgres-deploy/README.md)**: Guia completo de deployment, configuração e troubleshooting
- **[RabbitMQ](rabbitmq-deploy/README.md)**: Configuração de mensageria e management UI
- **[Redis](redis-deploy/README.md)**: Cache e armazenamento de sessões
- **[Prometheus](prometheus-deploy/README.md)**: Monitoramento e métricas
- **[ArgoCD](argo-cd-deploy/README.md)**: GitOps e continuous delivery
- **[Ingress](ingress-deploy/README.md)**: Configuração de acesso externo e domínios

## 📋 Scripts de Deployment

### Script Master
- **`deploy-all-infrastructure.sh`**: Script completo que executa todos os deployments em sequência

### Scripts Individuais
Cada componente possui seu próprio script de deployment localizado em:
- `postgres-deploy/deploy.sh`
- `rabbitmq-deploy/deploy-rabbitmq.sh`
- `redis-deploy/deploy-redis.sh`
- `prometheus-deploy/deploy-prometheus.sh`
- `argo-cd-deploy/deploy-argo-cd.sh`
- `ingress-deploy/deploy-infrastructure-ingress.sh`

## 🚪 Acesso Externo

Para expor os serviços externamente, utilize o Ingress:

```bash
# Criar o Ingress
kubectl apply -f infrastructure-ingress.yaml

# Verificar o Ingress
kubectl get ingress -n infrastructure
```

### Observações sobre o Ingress

- O Ingress é configurado para rotear o tráfego externo para os serviços internos
- Certifique-se de que o controlador de Ingress está instalado e configurado no Minikube
- Para serviços não-HTTP, use o arquivo `infrastructure-tcp-services.yaml` para configuração adicional
