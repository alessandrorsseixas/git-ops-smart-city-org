# PostgreSQL Deployment - Smart City Infrastructure

Este diretório contém os arquivos necessários para fazer o deployment do PostgreSQL no ambiente de desenvolvimento usando Helm e Minikube.

## 📁 Conteúdo do Diretório

```
postgres-deploy/
├── README.md                    # Este arquivo
├── deploy.sh                    # Script de deployment
└── postgres-minikube-values.yaml # Valores específicos para Minikube
```

## 🚀 Deployment

### Método 1: Usando o Script Automático

```bash
# Tornar o script executável (se necessário)
chmod +x deploy.sh

# Executar o deployment
./deploy.sh
```

### Método 2: Deployment Manual

```bash
# Adicionar repositório Helm do Bitnami
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Instalar PostgreSQL
helm install postgres bitnami/postgresql \
  -f postgres-minikube-values.yaml \
  -n infrastructure \
  --create-namespace
```

## ⚙️ Configuração

### Valores Personalizados (postgres-minikube-values.yaml)

```yaml
# Configurações específicas para Minikube
global:
  storageClass: standard

# Credenciais do banco
auth:
  postgresPassword: "admin123"
  username: "smartcity"
  password: "smartcity123"
  database: "smartcity"

# Configuração do serviço
service:
  type: ClusterIP  # Compatível com Minikube

# Configuração de persistência
persistence:
  enabled: true
  size: 8Gi

# Configuração de recursos
resources:
  requests:
    memory: 256Mi
    cpu: 250m
  limits:
    memory: 512Mi
    cpu: 500m
```

## 🔍 Verificação do Deployment

```bash
# Verificar se o pod está rodando
kubectl get pods -n infrastructure

# Verificar o serviço
kubectl get svc -n infrastructure

# Verificar PVC
kubectl get pvc -n infrastructure
```

## 📊 Acesso ao PostgreSQL

### Método 1: Port Forwarding (Recomendado)

```bash
# Fazer port forwarding
kubectl port-forward -n infrastructure svc/postgres 5432:5432

# Conectar via psql
psql -h localhost -p 5432 -U smartcity -d smartcity
```

### Método 2: Conexão Interna no Cluster

```bash
# Executar psql dentro do pod
kubectl exec -it -n infrastructure postgres-0 -- psql -U smartcity -d smartcity
```

## 📝 Informações de Conexão

- **Host**: `postgres.infrastructure.svc.cluster.local` (interno)
- **Porta**: `5432`
- **Banco**: `smartcity`
- **Usuário**: `smartcity`
- **Senha**: `smartcity123`
- **Usuário Admin**: `postgres`
- **Senha Admin**: `admin123`

## 🔧 Configuração da Aplicação

Para conectar sua aplicação ao PostgreSQL, use estas configurações:

### Spring Boot
```yaml
spring:
  datasource:
    url: jdbc:postgresql://postgres.infrastructure.svc.cluster.local:5432/smartcity
    username: smartcity
    password: smartcity123
    driver-class-name: org.postgresql.Driver
```

### Node.js
```javascript
const dbConfig = {
  host: 'postgres.infrastructure.svc.cluster.local',
  port: 5432,
  database: 'smartcity',
  username: 'smartcity',
  password: 'smartcity123'
};
```

## 🧹 Limpeza

```bash
# Remover o deployment
helm uninstall postgres -n infrastructure

# Remover PVC (cuidado: isso apaga os dados)
kubectl delete pvc -n infrastructure -l app.kubernetes.io/instance=postgres
```

## 📋 Próximos Passos

1. Verificar se o PostgreSQL está funcionando corretamente
2. Testar a conectividade da aplicação
3. Configurar backup se necessário
4. Ajustar recursos conforme necessário

## 🔍 Troubleshooting

### Problema: Pod não inicia
```bash
# Verificar logs
kubectl logs -n infrastructure postgres-0

# Verificar eventos
kubectl describe pod -n infrastructure postgres-0
```

### Problema: Não consegue conectar
```bash
# Verificar se o serviço existe
kubectl get svc -n infrastructure

# Testar conectividade
kubectl exec -it -n infrastructure postgres-0 -- psql -U smartcity -d smartcity -c "SELECT version();"
```

### Problema: Sem espaço em disco
```bash
# Verificar PVC
kubectl get pvc -n infrastructure

# Verificar uso de disco
kubectl describe pvc -n infrastructure postgres-pvc
```
