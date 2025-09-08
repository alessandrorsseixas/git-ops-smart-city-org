# Dev infra (k8s/infra/dev)

This folder contains Kubernetes manifests for local development (Minikube).

## Structure

### Deployments & StatefulSets
- `postgres-statefulset.yaml` - PostgreSQL database
- `redis-deployment.yaml` - Redis cache
- `rabbitmq-deployment.yaml` - RabbitMQ message broker  
- `keycloak-deployment.yaml` - Keycloak identity provider

### Secrets
- `postgres-secret.yaml` - PostgreSQL credentials
- `redis-secret.yaml` - Redis configuration
- `rabbitmq-secret.yaml` - RabbitMQ credentials
- `keycloak-secret.yaml` - Keycloak admin credentials

**⚠️ WARNING:** Secrets here are dev-only and use `stringData` with placeholder values.
**DO NOT use these secrets in production.**

### Persistent Volume Claims (PVCs)
- `postgres-pvc.yaml` - PostgreSQL data storage (5Gi)
- `mongodb-pvc.yaml` - MongoDB data storage (3Gi)
- `rabbitmq-pvc.yaml` - RabbitMQ data storage (2Gi)
- `redis-pvc.yaml` - Redis data storage (1Gi)
- `keycloak-pvc.yaml` - Keycloak data storage (1Gi)
- `n8n-pvc.yaml` - n8n workflow data storage (2Gi)

## Usage

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
```

### Apply all infrastructure
```bash
kubectl apply -k k8s/infra/dev
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
