# Smart City Infrastructure - Kustomize Structure

Este documento explica a estrutura organizada do Kustomize para a infraestrutura do Smart City.

## 📁 Estrutura de Diretórios

```
k8s/infra/dev/
├── kustomization.yaml          # Kustomization principal
├── mongo/                      # MongoDB
│   ├── kustomization.yaml
│   └── [manifests...]
├── postgres/                   # PostgreSQL
│   ├── kustomization.yaml
│   └── [manifests...]
├── redis/                      # Redis
│   ├── kustomization.yaml
│   └── [manifests...]
├── rabbitmq/                   # RabbitMQ
│   ├── kustomization.yaml
│   └── [manifests...]
├── keycloack/                  # Keycloak
│   ├── kustomization.yaml
│   └── [manifests...]
├── argocd/                     # ArgoCD
│   ├── kustomization.yaml
│   └── [manifests...]
└── n8n-pvc.yaml               # PVC adicional
```

## 🏗️ Arquitetura do Kustomize

### Kustomization Principal (`kustomization.yaml`)

O arquivo principal coordena todos os componentes:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

metadata:
  name: smartcity-infrastructure
  namespace: smartcity

resources:
  - mongo/          # Referencia kustomization.yaml do mongo
  - postgres/       # Referencia kustomization.yaml do postgres
  - redis/          # Referencia kustomization.yaml do redis
  - rabbitmq/       # Referencia kustomization.yaml do rabbitmq
  - keycloack/      # Referencia kustomization.yaml do keycloak
  - argocd/         # Referencia kustomization.yaml do argocd
  - n8n-pvc.yaml    # PVC individual
```

### Kustomization por Componente

Cada componente tem seu próprio `kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

metadata:
  name: [component-name]
  namespace: smartcity

commonLabels:
  app: [component-name]
  component: [component-type]
  environment: development
  managed-by: kustomize

resources:
  - [component]-secret.yaml
  - [component]-configmap.yaml
  - [component]-pvc.yaml
  - [component]-deployment.yaml
  # ... outros manifests

images:
  - name: [image-name]
    newTag: "[version]"
```

## 🚀 Como Usar

### Deploy de Toda a Infraestrutura

```bash
# Deploy tudo
kubectl apply -k k8s/infra/dev/

# Verificar status
kubectl get all -n smartcity
```

### Deploy de Componente Específico

```bash
# Deploy apenas MongoDB
kubectl apply -k k8s/infra/dev/mongo/

# Deploy apenas PostgreSQL
kubectl apply -k k8s/infra/dev/postgres/

# Deploy apenas Redis
kubectl apply -k k8s/infra/dev/redis/
```

### Deploy com Overlays (Para Diferentes Ambientes)

```bash
# Para staging
kubectl apply -k k8s/infra/staging/

# Para produção
kubectl apply -k k8s/infra/prod/
```

## ⚙️ Configurações por Ambiente

### Desenvolvimento (`dev/`)
- Recursos mínimos
- Configurações de debug habilitadas
- Backups frequentes
- Acesso administrativo completo

### Staging (`staging/`)
- Recursos intermediários
- Configurações otimizadas
- Backups diários
- Acesso controlado

### Produção (`prod/`)
- Recursos máximos
- Configurações de performance
- Backups redundantes
- Segurança máxima

## 🏷️ Labels e Annotations

### Labels Comuns

Todos os recursos recebem automaticamente:

```yaml
labels:
  environment: development
  managed-by: kustomize
  project: smartcity
  app: [component-name]
  component: [component-type]
```

### Labels por Componente

Cada componente adiciona labels específicos:

- **MongoDB**: `component: database`, `app: mongodb`
- **PostgreSQL**: `component: database`, `app: postgres`
- **Redis**: `component: cache`, `app: redis`
- **RabbitMQ**: `component: messaging`, `app: rabbitmq`

## 🔄 Estratégia de Deploy

### Ordem de Deploy

1. **Secrets e ConfigMaps** - Primeiro
2. **PersistentVolumeClaims** - Segundo
3. **Services** - Terceiro
4. **Deployments/StatefulSets** - Quarto
5. **NetworkPolicies** - Quinto
6. **CronJobs** - Último

### Dependências

- **MongoDB/PostgreSQL**: Não têm dependências
- **Redis**: Não tem dependências
- **RabbitMQ**: Não tem dependências
- **Keycloak**: Pode depender de PostgreSQL
- **ArgoCD**: Independente

## 📊 Monitoramento

### Health Checks

```bash
# Verificar todos os componentes
kubectl get all -n smartcity

# Verificar por componente
kubectl get all -n smartcity -l app=mongodb
kubectl get all -n smartcity -l app=postgres
kubectl get all -n smartcity -l component=database
```

### Logs

```bash
# Logs por componente
kubectl logs -n smartcity -l app=redis
kubectl logs -n smartcity -l app=rabbitmq

# Logs de backup jobs
kubectl logs -n smartcity -l component=backup
```

## 🔧 Manutenção

### Atualização de Imagens

Para atualizar versões das imagens:

```yaml
# Em kustomization.yaml do componente
images:
  - name: mongo
    newTag: "7.0"  # Atualizar versão
```

### Scaling

```bash
# Scale Redis
kubectl scale deployment redis --replicas=2 -n smartcity

# Scale RabbitMQ
kubectl scale deployment rabbitmq --replicas=3 -n smartcity
```

### Backup e Restore

Cada componente tem seus próprios scripts de backup:

```bash
# MongoDB
cd k8s/infra/dev/mongo/
./deploy-mongodb.sh

# PostgreSQL
cd k8s/infra/dev/postgres/
./deploy-postgres.sh

# Redis
cd k8s/infra/dev/redis/
./deploy-redis.sh

# RabbitMQ
cd k8s/infra/dev/rabbitmq/
./deploy-rabbitmq.sh
```

## 🚨 Troubleshooting

### Problemas Comuns

1. **PVC Pending**: Verificar storage class
2. **Pod CrashLoopBackOff**: Verificar logs e configurações
3. **Service Unavailable**: Verificar selectors e labels
4. **Network Issues**: Verificar NetworkPolicies

### Comandos Úteis

```bash
# Ver todos os recursos
kubectl get all -n smartcity

# Ver recursos por componente
kubectl get all -n smartcity -l component=database

# Ver events
kubectl get events -n smartcity --sort-by=.metadata.creationTimestamp

# Ver resource usage
kubectl top pods -n smartcity
```

## 📚 Referências

- [Kustomize Documentation](https://kubectl.docs.kubernetes.io/references/kustomize/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [GitOps with ArgoCD](https://argo-cd.readthedocs.io/)

---

**Nota**: Esta estrutura facilita a manutenção, escalabilidade e organização da infraestrutura do Smart City, seguindo as melhores práticas do Kubernetes e Kustomize.
