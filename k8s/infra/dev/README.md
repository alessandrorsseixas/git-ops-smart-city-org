# Dev infra (k8s/infra/dev)

This folder contains Kubernetes manifests for local development (Minikube).

## Structure

### Deployments & StatefulSets
- `postgres-statefulset.yaml` - PostgreSQL database
- `redis-deployment.yaml` - Redis cache
- `rabbitmq-deployment.yaml` - RabbitMQ message broker  
- `keycloak-deployment.yaml` - Keycloak identity provider
- `argocd-deployment.yaml` - ArgoCD GitOps controller and UI

### Secrets
- `postgres-secret.yaml` - PostgreSQL credentials
- `redis-secret.yaml` - Redis configuration
- `rabbitmq-secret.yaml` - RabbitMQ credentials
- `keycloak-secret.yaml` - Keycloak admin credentials
- `argocd-secret.yaml` - ArgoCD admin credentials and OIDC config

**⚠️ WARNING:** Secrets here are dev-only and use `stringData` with placeholder values.
**DO NOT use these secrets in production.**

### Persistent Volume Claims (PVCs)
- `postgres-pvc.yaml` - PostgreSQL data storage (5Gi)
- `mongodb-pvc.yaml` - MongoDB data storage (3Gi)
- `rabbitmq-pvc.yaml` - RabbitMQ data storage (2Gi)
- `redis-pvc.yaml` - Redis data storage (1Gi)
- `keycloak-pvc.yaml` - Keycloak data storage (1Gi)
- `n8n-pvc.yaml` - n8n workflow data storage (2Gi)
- `argocd-pvc.yaml` - ArgoCD data storage (10Gi repo-server, 5Gi server)

### ArgoCD GitOps Resources
- `argocd-namespace.yaml` - ArgoCD namespace
- `argocd-configmap.yaml` - ArgoCD main configuration
- `argocd-additional-configmaps.yaml` - Additional ArgoCD configurations
- `argocd-serviceaccount.yaml` - Service accounts for ArgoCD components
- `argocd-rbac.yaml` - RBAC roles and bindings
- `argocd-service.yaml` - Services for ArgoCD components
- `argocd-ingress.yaml` - Ingress for ArgoCD UI and GRPC access

## Usage

### Deploy ArgoCD (Quick Start)
```bash
# Deploy ArgoCD with all components
./deploy-argocd.sh
```

### Apply all PVCs
```bash
# Run the script to apply all PVCs
./apply-pvcs.sh

# Or manually apply each one
kubectl apply -f postgres-pvc.yaml
kubectl apply -f mongodb-pvc.yaml
kubectl apply -f rabbitmq-pvc.yaml
kubectl apply -f redis-pvc.yaml
kubectl apply -f keycloak-pvc.yaml
kubectl apply -f n8n-pvc.yaml
kubectl apply -f argocd-pvc.yaml
```

### Apply all infrastructure
```bash
kubectl apply -k k8s/infra/dev
```

### ArgoCD Access
After deployment, access ArgoCD at:
- **UI**: https://argocd.dev.smartcity.local
- **GRPC**: argocd-grpc.dev.smartcity.local:443
- **Username**: admin
- **Password**: admin123 (default, check deployment output for actual password)

Add to `/etc/hosts`:
```
<MINIKUBE_IP> argocd.dev.smartcity.local argocd-grpc.dev.smartcity.local
```

### ArgoCD CLI Setup
```bash
# Install ArgoCD CLI
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

# Login
argocd login argocd-grpc.dev.smartcity.local --username admin --password admin123 --insecure
```

### How to regenerate secrets locally
```bash
# Using kubectl create secret:
kubectl create secret generic postgres-secrets \
  --from-literal=POSTGRES_USER=postgres \
  --from-literal=POSTGRES_PASSWORD=postgres -n smartcity

# Or apply the provided secret manifests:
kubectl apply -f postgres-secret.yaml
kubectl apply -f redis-secret.yaml  
kubectl apply -f rabbitmq-secret.yaml
kubectl apply -f keycloak-secret.yaml
```

## Notes
- For production, use SealedSecrets / ExternalSecrets / Vault.
- Adjust resources in manifests if your Minikube has less than 2 CPU / 4Gi memory.
- PVCs use `standard` storage class (default in Minikube).
