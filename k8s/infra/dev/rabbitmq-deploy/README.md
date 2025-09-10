# RabbitMQ Deployment - Smart City Infrastructure

Este diretório contém os arquivos necessários para fazer o deployment do RabbitMQ no ambiente de desenvolvimento usando Helm e Minikube.

## 📁 Conteúdo do Diretório

```
rabbitmq-deploy/
├── README.md                      # Este arquivo
├── deploy-rabbitmq.sh            # Script de deployment
└── rabbitmq-values-minikube.yaml # Valores específicos para Minikube
```

## 🚀 Deployment

### Método 1: Usando o Script Automático

```bash
# Tornar o script executável (se necessário)
chmod +x deploy-rabbitmq.sh

# Executar o deployment
./deploy-rabbitmq.sh
```

### Método 2: Deployment Manual

```bash
# Adicionar repositório Helm do Bitnami
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Instalar RabbitMQ
helm install rabbitmq bitnami/rabbitmq \
  -f rabbitmq-values-minikube.yaml \
  -n infrastructure \
  --create-namespace
```

## ⚙️ Configuração

### Valores Personalizados (rabbitmq-values-minikube.yaml)

```yaml
# Configurações específicas para Minikube
global:
  storageClass: standard

# Credenciais de acesso
auth:
  username: admin
  password: admin123
  erlangCookie: smartcity-rabbitmq-cookie

# Configuração do serviço
service:
  type: ClusterIP  # Compatível com Minikube
  ports:
    amqp: 5672
    management: 15672

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

# Plugins habilitados
plugins: "rabbitmq_management rabbitmq_prometheus"
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

## 📊 Acesso ao RabbitMQ

### Método 1: Management UI via Port Forwarding

```bash
# Fazer port forwarding para a interface de gerenciamento
kubectl port-forward -n infrastructure svc/rabbitmq 15672:15672

# Acessar no navegador: http://localhost:15672
# Usuário: admin
# Senha: admin123
```

### Método 2: Conexão AMQP

```bash
# Fazer port forwarding para AMQP
kubectl port-forward -n infrastructure svc/rabbitmq 5672:5672

# Conectar via aplicação
# Host: localhost
# Port: 5672
# User: admin
# Password: admin123
```

## 📝 Informações de Conexão

### AMQP (para aplicações)
- **Host**: `rabbitmq.infrastructure.svc.cluster.local` (interno)
- **Porta**: `5672`
- **Usuário**: `admin`
- **Senha**: `admin123`
- **Virtual Host**: `/`

### Management UI
- **URL**: `http://rabbitmq.infrastructure.svc.cluster.local:15672`
- **Usuário**: `admin`
- **Senha**: `admin123`

## 🔧 Configuração da Aplicação

### Spring Boot com Spring AMQP
```yaml
spring:
  rabbitmq:
    host: rabbitmq.infrastructure.svc.cluster.local
    port: 5672
    username: admin
    password: admin123
    virtual-host: /
```

### Node.js com amqplib
```javascript
const rabbitConfig = {
  hostname: 'rabbitmq.infrastructure.svc.cluster.local',
  port: 5672,
  username: 'admin',
  password: 'admin123',
  vhost: '/'
};
```

### Python com pika
```python
rabbit_config = {
    'host': 'rabbitmq.infrastructure.svc.cluster.local',
    'port': 5672,
    'credentials': pika.PlainCredentials('admin', 'admin123'),
    'virtual_host': '/'
}
```

## 📋 Exchanges e Filas Padrão

Após o deployment, o RabbitMQ terá estas configurações padrão:

- **Exchange**: Nenhum (use o default)
- **Filas**: Criadas dinamicamente pelas aplicações
- **Virtual Host**: `/`

## 🧹 Limpeza

```bash
# Remover o deployment
helm uninstall rabbitmq -n infrastructure

# Remover PVC (cuidado: isso apaga as mensagens persistidas)
kubectl delete pvc -n infrastructure -l app.kubernetes.io/instance=rabbitmq
```

## 📋 Próximos Passos

1. Verificar se o RabbitMQ está funcionando corretamente
2. Acessar a interface de gerenciamento
3. Configurar exchanges e filas necessárias
4. Testar conectividade da aplicação
5. Configurar monitoramento se necessário

## 🔍 Troubleshooting

### Problema: Management UI não carrega
```bash
# Verificar se o plugin de management está habilitado
kubectl exec -it -n infrastructure rabbitmq-0 -- rabbitmq-plugins list

# Verificar logs
kubectl logs -n infrastructure rabbitmq-0
```

### Problema: Não consegue conectar via AMQP
```bash
# Verificar se o serviço está exposto
kubectl get svc -n infrastructure

# Testar conectividade interna
kubectl exec -it -n infrastructure rabbitmq-0 -- rabbitmq-diagnostics ping
```

### Problema: Sem espaço em disco
```bash
# Verificar PVC
kubectl get pvc -n infrastructure

# Verificar uso de disco
kubectl describe pvc -n infrastructure rabbitmq-pvc
```

### Problema: Credenciais inválidas
```bash
# Verificar credenciais no pod
kubectl exec -it -n infrastructure rabbitmq-0 -- env | grep RABBITMQ

# Resetar senha se necessário
kubectl exec -it -n infrastructure rabbitmq-0 -- rabbitmqctl change_password admin nova_senha
```
