# Redis Deployment - Smart City Infrastructure

Este diretório contém os arquivos necessários para fazer o deployment do Redis no ambiente de desenvolvimento usando Helm e Minikube.

## 📁 Conteúdo do Diretório

```
redis-deploy/
├── README.md                 # Este arquivo
├── deploy-redis.sh          # Script de deployment
└── redis-values-minikube.yaml # Valores específicos para Minikube
```

## 🚀 Deployment

### Método 1: Usando o Script Automático

```bash
# Tornar o script executável (se necessário)
chmod +x deploy-redis.sh

# Executar o deployment
./deploy-redis.sh
```

### Método 2: Deployment Manual

```bash
# Adicionar repositório Helm do Bitnami
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Instalar Redis
helm install redis bitnami/redis \
  -f redis-values-minikube.yaml \
  -n infrastructure \
  --create-namespace
```

## ⚙️ Configuração

### Valores Personalizados (redis-values-minikube.yaml)

```yaml
# Configurações específicas para Minikube
global:
  storageClass: standard

# Modo standalone (sem cluster)
architecture: standalone

# Credenciais de acesso
auth:
  enabled: true
  password: "redis123"

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

# Configurações do Redis
master:
  configmap: |-
    # Redis configuration
    maxmemory 256mb
    maxmemory-policy allkeys-lru
    tcp-keepalive 300
    timeout 300
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

## 📊 Acesso ao Redis

### Método 1: Conexão Direta via Port Forwarding

```bash
# Fazer port forwarding
kubectl port-forward -n infrastructure svc/redis-master 6379:6379

# Conectar via redis-cli
redis-cli -h localhost -p 6379 -a redis123
```

### Método 2: Conexão Interna no Cluster

```bash
# Executar redis-cli dentro do pod
kubectl exec -it -n infrastructure redis-master-0 -- redis-cli -a redis123
```

## 📝 Informações de Conexão

- **Host**: `redis-master.infrastructure.svc.cluster.local` (interno)
- **Porta**: `6379`
- **Senha**: `redis123`
- **Modo**: Standalone

## 🔧 Configuração da Aplicação

### Spring Boot com Spring Data Redis
```yaml
spring:
  redis:
    host: redis-master.infrastructure.svc.cluster.local
    port: 6379
    password: redis123
    timeout: 2000ms
```

### Node.js com ioredis
```javascript
const redisConfig = {
  host: 'redis-master.infrastructure.svc.cluster.local',
  port: 6379,
  password: 'redis123'
};
```

### Python com redis-py
```python
redis_config = {
    'host': 'redis-master.infrastructure.svc.cluster.local',
    'port': 6379,
    'password': 'redis123',
    'decode_responses': True
}
```

## 💾 Casos de Uso Recomendados

### Cache de Aplicação
```bash
# Armazenar dados temporários
SET user:123:name "João Silva" EX 3600

# Recuperar dados
GET user:123:name
```

### Sessões de Usuário
```bash
# Armazenar sessão
SET session:abc123:user_id "123" EX 1800

# Verificar sessão
GET session:abc123:user_id
```

### Contadores e Estatísticas
```bash
# Incrementar contador
INCR page_views:home

# Obter valor
GET page_views:home
```

## 🧹 Limpeza

```bash
# Remover o deployment
helm uninstall redis -n infrastructure

# Remover PVC (cuidado: isso apaga os dados em cache)
kubectl delete pvc -n infrastructure -l app.kubernetes.io/instance=redis
```

## 📋 Próximos Passos

1. Verificar se o Redis está funcionando corretamente
2. Testar operações básicas de cache
3. Configurar monitoramento se necessário
4. Ajustar configurações de memória conforme necessário

## 🔍 Troubleshooting

### Problema: Conexão recusada
```bash
# Verificar se o pod está rodando
kubectl get pods -n infrastructure

# Verificar logs
kubectl logs -n infrastructure redis-master-0

# Testar conectividade
kubectl exec -it -n infrastructure redis-master-0 -- redis-cli ping
```

### Problema: Autenticação falha
```bash
# Verificar senha configurada
kubectl exec -it -n infrastructure redis-master-0 -- env | grep REDIS_PASSWORD

# Testar conexão com senha
kubectl exec -it -n infrastructure redis-master-0 -- redis-cli -a redis123 ping
```

### Problema: Memória cheia
```bash
# Verificar uso de memória
kubectl exec -it -n infrastructure redis-master-0 -- redis-cli info memory

# Verificar política de remoção
kubectl exec -it -n infrastructure redis-master-0 -- redis-cli config get maxmemory-policy
```

### Problema: Dados não persistem
```bash
# Verificar configuração de persistência
kubectl describe pvc -n infrastructure redis-pvc

# Verificar se AOF está habilitado
kubectl exec -it -n infrastructure redis-master-0 -- redis-cli config get appendonly
```

## 📊 Monitoramento

### Comandos Úteis para Monitoramento
```bash
# Informações gerais
kubectl exec -it -n infrastructure redis-master-0 -- redis-cli info

# Estatísticas de comandos
kubectl exec -it -n infrastructure redis-master-0 -- redis-cli info commandstats

# Conexões ativas
kubectl exec -it -n infrastructure redis-master-0 -- redis-cli info clients
```
