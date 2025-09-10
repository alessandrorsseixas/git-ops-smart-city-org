# Ingress da Infraestrutura Smart City

Este diretório contém as configurações de Ingress para expor os serviços de infraestrutura do Smart City através de domínios personalizados no padrão `servico.dev.smartcity.local`.

## 📁 Conteúdo do Diretório

```
├── infrastructure-ingress.yaml          # Ingress principal com regras HTTP
├── infrastructure-tcp-services.yaml     # Configurações para serviços TCP
├── deploy-infrastructure-ingress.sh     # Script de deployment automatizado
└── README.md                           # Este arquivo
```

## 🚀 Deployment

### Método 1: Usando o Script Automático

```bash
# Tornar o script executável
chmod +x deploy-infrastructure-ingress.sh

# Executar o deployment
./deploy-infrastructure-ingress.sh
```

### Método 2: Deployment Manual

```bash
# 1. Instalar NGINX Ingress Controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.http=30080 \
  --set controller.service.nodePorts.https=30443

# 2. Aplicar configurações do Ingress
kubectl apply -f infrastructure-ingress.yaml
kubectl apply -f infrastructure-tcp-services.yaml
```

## ⚙️ Configuração dos Domínios

### Domínios Configurados

| Serviço | Domínio | Porta | Protocolo |
|---------|---------|-------|-----------|
| PostgreSQL | `postgres.dev.smartcity.local` | 5432 | TCP |
| RabbitMQ Management | `rabbitmq.dev.smartcity.local` | 15672 | HTTP |
| Redis | `redis.dev.smartcity.local` | 6379 | TCP |
| Prometheus | `prometheus.dev.smartcity.local` | 9090 | HTTP |
| ArgoCD | `argocd.dev.smartcity.local` | 8080 | HTTP |
| Grafana | `grafana.dev.smartcity.local` | 80 | HTTP |
| Keycloak | `keycloak.dev.smartcity.local` | 8080 | HTTP |
| MongoDB | `mongodb.dev.smartcity.local` | 27017 | TCP |
| Smart City App | `app.dev.smartcity.local` | 8080 | HTTP |
| Smart City API | `api.dev.smartcity.local` | 8080 | HTTP |

### Configuração do /etc/hosts (Minikube)

Para desenvolvimento local, adicione ao `/etc/hosts`:

```bash
# Obter IP do Minikube
MINIKUBE_IP=$(minikube ip)

# Adicionar entradas
echo "${MINIKUBE_IP} postgres.dev.smartcity.local" | sudo tee -a /etc/hosts
echo "${MINIKUBE_IP} rabbitmq.dev.smartcity.local" | sudo tee -a /etc/hosts
echo "${MINIKUBE_IP} redis.dev.smartcity.local" | sudo tee -a /etc/hosts
echo "${MINIKUBE_IP} prometheus.dev.smartcity.local" | sudo tee -a /etc/hosts
echo "${MINIKUBE_IP} argocd.dev.smartcity.local" | sudo tee -a /etc/hosts
echo "${MINIKUBE_IP} grafana.dev.smartcity.local" | sudo tee -a /etc/hosts
echo "${MINIKUBE_IP} keycloak.dev.smartcity.local" | sudo tee -a /etc/hosts
echo "${MINIKUBE_IP} mongodb.dev.smartcity.local" | sudo tee -a /etc/hosts
echo "${MINIKUBE_IP} app.dev.smartcity.local" | sudo tee -a /etc/hosts
echo "${MINIKUBE_IP} api.dev.smartcity.local" | sudo tee -a /etc/hosts
```

## 🔍 Verificação do Deployment

```bash
# Verificar Ingress
kubectl get ingress -n infrastructure

# Verificar serviços
kubectl get svc -n ingress-nginx

# Verificar pods do Ingress Controller
kubectl get pods -n ingress-nginx

# Verificar configurações
kubectl describe ingress infrastructure-ingress -n infrastructure
```

## 📊 Acesso aos Serviços

### HTTP Services (via Browser)

```bash
# RabbitMQ Management
open http://rabbitmq.dev.smartcity.local

# Prometheus
open http://prometheus.dev.smartcity.local

# ArgoCD
open http://argocd.dev.smartcity.local

# Grafana
open http://grafana.dev.smartcity.local
```

### TCP Services (via Port Forwarding)

```bash
# PostgreSQL
kubectl port-forward -n ingress-nginx svc/ingress-nginx-tcp 5432:5432
psql -h localhost -p 5432 -U smartcity -d smartcity

# Redis
kubectl port-forward -n ingress-nginx svc/ingress-nginx-tcp 6379:6379
redis-cli -h localhost -p 6379 -a redis123

# MongoDB
kubectl port-forward -n ingress-nginx svc/ingress-nginx-tcp 27017:27017
mongosh --host localhost --port 27017
```

## 🔧 Configurações Avançadas

### SSL/TLS

Para habilitar SSL em produção:

```yaml
# Adicionar ao infrastructure-ingress.yaml
spec:
  tls:
  - hosts:
    - postgres.dev.smartcity.local
    - rabbitmq.dev.smartcity.local
    secretName: smartcity-tls
```

### Rate Limiting

```yaml
# Annotations para rate limiting
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
```

### Autenticação Básica

```yaml
# Annotations para auth básica
metadata:
  annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required'
```

## 🧹 Limpeza

```bash
# Remover Ingress
kubectl delete -f infrastructure-ingress.yaml
kubectl delete -f infrastructure-tcp-services.yaml

# Remover Ingress Controller
helm uninstall ingress-nginx -n ingress-nginx
kubectl delete namespace ingress-nginx
```

## 📋 Próximos Passos

1. **Testar conectividade**: Verifique se todos os domínios estão acessíveis
2. **Configurar aplicações**: Atualize suas aplicações para usar os novos domínios
3. **SSL em produção**: Configure certificados SSL para produção
4. **Monitoramento**: Configure monitoring do Ingress Controller
5. **Segurança**: Implemente WAF e outras medidas de segurança

## 🔍 Troubleshooting

### Problema: 404 Not Found

```bash
# Verificar se o serviço existe
kubectl get svc -n infrastructure

# Verificar se o Ingress está roteando corretamente
kubectl describe ingress infrastructure-ingress -n infrastructure

# Testar conectividade direta
kubectl port-forward svc/<service-name> 8080:80 -n infrastructure
```

### Problema: DNS não resolve

```bash
# Verificar /etc/hosts
cat /etc/hosts | grep smartcity

# Testar resolução DNS
nslookup postgres.dev.smartcity.local

# Para produção, configure DNS records
```

### Problema: Certificado SSL

```bash
# Verificar certificado
kubectl get secret smartcity-tls -n infrastructure

# Verificar configuração TLS no Ingress
kubectl describe ingress infrastructure-ingress -n infrastructure
```

### Problema: Rate Limiting

```bash
# Verificar logs do Ingress Controller
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Verificar métricas
kubectl port-forward svc/ingress-nginx-controller-metrics 10254:10254 -n ingress-nginx
curl http://localhost:10254/metrics
```

## 📊 Monitoramento

### Métricas do Ingress Controller

```bash
# Expor métricas
kubectl port-forward svc/ingress-nginx-controller-metrics 10254:10254 -n ingress-nginx

# Acessar métricas
curl http://localhost:10254/metrics
```

### Logs do Ingress Controller

```bash
# Ver logs em tempo real
kubectl logs -f -n ingress-nginx deployment/ingress-nginx-controller

# Ver logs de um pod específico
kubectl logs -n ingress-nginx <pod-name>
```

## 🔗 Integrações

### Com Cert-Manager (SSL Automático)

```bash
# Instalar Cert-Manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.yaml

# Configurar ClusterIssuer
kubectl apply -f letsencrypt-issuer.yaml

# Adicionar annotations ao Ingress
annotations:
  cert-manager.io/cluster-issuer: letsencrypt-prod
```

### Com External-DNS (DNS Automático)

```bash
# Instalar External-DNS
helm install external-dns bitnami/external-dns

# Configurar para seu provider DNS
```

## 📝 Notas Importantes

- **Desenvolvimento**: Use `/etc/hosts` para resolução local
- **Produção**: Configure registros DNS apropriados
- **TCP Services**: Alguns serviços requerem port-forwarding devido a limitações do Ingress
- **SSL**: Sempre use HTTPS em produção
- **Monitoramento**: Configure alertas para disponibilidade dos serviços

## 🎯 Benefícios

✅ **Domínios consistentes** no padrão `servico.dev.smartcity.local`
✅ **Centralização** do controle de acesso
✅ **Load balancing** automático
✅ **SSL termination** centralizado
✅ **Monitoramento unificado** de todos os serviços
✅ **Configuração simplificada** para aplicações
