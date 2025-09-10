# House Control Application

Aplicação de controle residencial para o Smart City, desenvolvida em Spring Boot.

## 📋 Pré-requisitos

- Kubernetes cluster (Minikube recomendado)
- NGINX Ingress Controller
- Serviços de infraestrutura:
  - PostgreSQL
  - Redis
  - RabbitMQ
  - Keycloak (opcional)

## 🚀 Deploy da Aplicação

### Método 1: Usando Kustomize (Recomendado)

```bash
# Deploy usando Kustomize
kubectl apply -k gitops/dev/house-control/

# Verificar o status
kubectl get pods -n house-control
kubectl get ingress -n house-control
```

### Método 2: Deploy Individual

```bash
# Criar namespace
kubectl apply -f gitops/dev/house-control/house-control-namespace.yaml

# Deploy dos recursos
kubectl apply -f gitops/dev/house-control/house-control-config-map.yaml
kubectl apply -f gitops/dev/house-control/house-control-secret.yaml
kubectl apply -f gitops/dev/house-control/house-control-deployment.yaml
kubectl apply -f gitops/dev/house-control/house-control-service.yaml
kubectl apply -f gitops/dev/house-control/house-control-ingress.yaml
kubectl apply -f gitops/dev/house-control/house-control-hpa.yaml
# kubectl apply -f gitops/dev/house-control/house-control-network-policy.yaml  # Arquivo não existe ainda
```

## 🌐 Acesso à Aplicação

### URL de Acesso
- **Local**: http://house-control.dev.smartcity.local
- **Minikube**: http://house-control.dev.smartcity.local (após configurar /etc/hosts)

### Configuração do /etc/hosts
```bash
# Adicionar ao /etc/hosts
echo "$(minikube ip) house-control.dev.smartcity.local" | sudo tee -a /etc/hosts
```

## 🔧 Configuração

### Padrão de Configuração

A aplicação utiliza um padrão consistente de configuração através de **variáveis de ambiente**:

#### ConfigMap (`house-control-config`)
Contém configurações não-sensíveis usando chaves individuais:
```yaml
SPRING_PROFILES_ACTIVE: "dev"
SPRING_DATASOURCE_URL: "jdbc:postgresql://..."
LOGGING_LEVEL_ROOT: "INFO"
```

#### Secret (`house-control-secret`)
Contém credenciais sensíveis codificadas em base64:
```yaml
SPRING_DATASOURCE_PASSWORD: "c21hcnRjaXR5MTIz"  # base64 encoded
RABBITMQ_USERNAME: "YWRtaW4="              # base64 encoded
```

### Benefícios do Padrão
- ✅ **Consistência**: Mesmo padrão para ConfigMap e Secret
- ✅ **Granularidade**: Controle fino sobre cada configuração
- ✅ **Segurança**: Credenciais separadas e codificadas
- ✅ **Flexibilidade**: Fácil sobrescrever valores via variáveis de ambiente
- ✅ **K8s Native**: Usa recursos nativos do Kubernetes eficientemente

### Porta da Aplicação
A aplicação está configurada para rodar na **porta 8080**, que é:
- Expõe no Dockerfile
- Configurada nos manifestos Kubernetes
- Usada pelas health checks
- Definida no Service e Ingress

### Variáveis de Ambiente

A aplicação usa as seguintes configurações via ConfigMap e Secret:

| Variável | Descrição | Valor Padrão |
|----------|-----------|---------------|
| `SPRING_PROFILES_ACTIVE` | Perfil Spring ativo | `dev` |
| `SPRING_DATASOURCE_URL` | URL do PostgreSQL | `jdbc:postgresql://postgres.infrastructure.svc.cluster.local:5432/smartcity` |
| `SPRING_REDIS_HOST` | Host do Redis | `redis.infrastructure.svc.cluster.local` |
| `SPRING_RABBITMQ_HOST` | Host do RabbitMQ | `rabbitmq.infrastructure.svc.cluster.local` |

### Health Checks

- **Liveness Probe**: `/actuator/health` (porta 8080)
- **Readiness Probe**: `/actuator/health` (porta 8080)

## 📊 Monitoramento

### HPA (Horizontal Pod Autoscaler)
- **Mínimo**: 1 réplica
- **Máximo**: 2 réplicas
- **CPU Target**: 80% de utilização

### Métricas Disponíveis
- **Health**: `/actuator/health`
- **Info**: `/actuator/info`
- **Metrics**: `/actuator/metrics`

## 🔒 Segurança

### Network Policy
A aplicação inclui uma NetworkPolicy que:
- Permite tráfego do NGINX Ingress Controller
- Permite comunicação com serviços de infraestrutura
- Bloqueia todo o tráfego não autorizado

## 🧪 Testes

### Verificar Conectividade
```bash
# Testar conectividade com a aplicação
curl -v http://house-control.dev.smartcity.local/actuator/health

# Verificar logs
kubectl logs -n house-control -l app=house-control-container

# Verificar eventos
kubectl get events -n house-control
```

### Testar Escalabilidade
```bash
# Simular carga para testar HPA
kubectl run load-generator --image=busybox --restart=Never --rm -i --tty -- /bin/sh
# Dentro do pod: while true; do wget -q -O- http://house-control.house-control.svc.cluster.local:8080/actuator/health; done

# Monitorar escalabilidade
kubectl get hpa -n house-control -w
```

## 🛠️ Desenvolvimento

### Atualização da Imagem
```bash
# Atualizar tag da imagem no kustomization.yaml
# Depois aplicar novamente
kubectl apply -k gitops/dev/house-control/
```

### Debug
```bash
# Verificar configuração da aplicação (agora via variáveis de ambiente)
kubectl exec -n house-control -it deployment/house-control -- env | grep -E "(SPRING|KEYCLOAK|LOGGING|MANAGEMENT|SERVER)"

# Verificar variáveis de ambiente específicas
kubectl exec -n house-control -it deployment/house-control -- env | grep SPRING_DATASOURCE

# Verificar conectividade com banco
kubectl exec -n house-control -it deployment/house-control -- nc -zv postgres.infrastructure.svc.cluster.local 5432
```

## 📝 Arquivos de Configuração

- `house-control-namespace.yaml` - Namespace da aplicação
- `house-control-config-map.yaml` - Configurações da aplicação (variáveis de ambiente)
- `house-control-secret.yaml` - Credenciais sensíveis (codificadas em base64)
- `house-control-deployment.yaml` - Deployment da aplicação
- `house-control-service.yaml` - Service para exposição interna
- `house-control-ingress.yaml` - Ingress para exposição externa
- `house-control-hpa.yaml` - Auto-scaling baseado em CPU
- `house-control-network-policy.yaml` - Políticas de rede *(arquivo não existe)*
- `kustomization.yaml` - Configuração do Kustomize

## 🚨 Troubleshooting

### Problema: Pods em CrashLoopBackOff
```bash
# Verificar logs detalhados
kubectl logs -n house-control -l app=house-control-container --previous

# Verificar eventos
kubectl describe pod -n house-control -l app=house-control-container
```

### Problema: Não consegue conectar ao banco
```bash
# Verificar se o serviço de PostgreSQL está acessível
kubectl get svc -n infrastructure postgres-main-postgresql

# Testar conectividade
kubectl exec -n house-control -it deployment/house-control -- nc -zv postgres.infrastructure.svc.cluster.local 5432
```

### Problema: Ingress não funciona
```bash
# Verificar status do Ingress Controller
kubectl get pods -n ingress-nginx

# Verificar configuração do Ingress
kubectl describe ingress -n house-control house-control-ingress
```

### Problema: Porta incorreta no Dockerfile
Se o Dockerfile estiver expondo uma porta diferente dos manifestos Kubernetes:
```bash
# Verificar porta no Dockerfile
grep "EXPOSE" Dockerfile

# Deve ser consistente com os manifestos:
# - Deployment: containerPort
# - Service: port e targetPort
# - Ingress: service port number
# - Health checks: httpGet port
```
