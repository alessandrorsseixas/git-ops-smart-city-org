# Deploy Scripts - Smart City GitOps (Development)

This directory contains deployment scripts for the Smart City GitOps platform development environment.

## 📁 Scripts Overview

| Script | Description | Purpose |
|--------|-------------|---------|
| `deploy-all.sh` | 🚀 Complete deployment | Deploys everything in order: Infrastructure → ArgoCD |
| `deploy-pvcs.sh` | 💾 PVC deployment | Creates all Persistent Volume Claims |
| `deploy-infra.sh` | 🏗️ Infrastructure deployment | Deploys PostgreSQL, Redis, RabbitMQ, Keycloak |
| `deploy-argocd.sh` | 🎯 ArgoCD deployment | Deploys ArgoCD GitOps platform |
| `deploy-component.sh` | 🔧 Component deployment | Deploy individual components using Kustomize |
| `kustomize-examples.sh` | 📚 Kustomize examples | Shows useful Kustomize commands and examples |
| `status.sh` | 📊 Status monitoring | Shows comprehensive status of all deployments |
| `cleanup.sh` | 🧹 Complete cleanup | Removes all resources and data |

## 🚀 Quick Start

### Full Deployment (Recommended)
```bash
# Deploy everything at once
./deploy-all.sh
```

### Step-by-Step Deployment
```bash
# 1. Deploy storage first
./deploy-pvcs.sh

# 2. Deploy infrastructure
./deploy-infra.sh

# 3. Deploy ArgoCD
./deploy-argocd.sh
```

### Individual Component Deployment
```bash
# Deploy specific components
./deploy-component.sh postgres
./deploy-component.sh redis
./deploy-component.sh argocd

# Deploy all components
./deploy-component.sh all
```

### Monitor Status
```bash
# Check deployment status
./status.sh
```

### Clean Everything
```bash
# Remove all resources and data
./cleanup.sh
```

## 📋 Prerequisites

### System Requirements
- **Kubernetes cluster** (Minikube recommended for dev)
- **kubectl** configured and connected
- **Minimum resources**: 2 CPU, 4GB RAM, 30GB disk
- **Storage provisioner** available (default StorageClass)

### Check Prerequisites
```bash
# Check kubectl
kubectl version --client

# Check cluster connectivity  
kubectl cluster-info

# Check storage class
kubectl get storageclass

# Check available resources (for Minikube)
minikube status
```

## 🏗️ Deployment Architecture

The deployment uses **Kustomize** for configuration management, providing:

- **Hierarchical organization** - Components organized in separate directories
- **Environment-specific overlays** - Easy switching between dev/staging/prod
- **DRY principles** - Common configurations shared across components
- **Version control** - All configurations tracked in Git
- **Modular deployments** - Deploy individual components or entire stacks

```
k8s/infra/dev/
├── kustomization.yaml          # Main configuration
├── postgres/                   # PostgreSQL component
│   ├── kustomization.yaml
│   └── [manifests...]
├── mongo/                      # MongoDB component
│   ├── kustomization.yaml
│   └── [manifests...]
├── redis/                      # Redis component
├── rabbitmq/                   # RabbitMQ component
├── keycloack/                  # Keycloak component
└── argocd/                     # ArgoCD component
```

### Kustomize Features Used

- **Common Labels** - Applied to all resources for better organization
- **Image Transformations** - Environment-specific image versions
- **ConfigMap Generators** - Environment-specific configurations
- **Resource Patches** - Fine-tuning for different environments
- **Namespace Management** - Automatic namespace assignment

## 🔧 Individual Component Deployment

The `deploy-component.sh` script allows flexible component management:

```bash
# Available components
./deploy-component.sh postgres    # PostgreSQL database
./deploy-component.sh mongo       # MongoDB database
./deploy-component.sh redis       # Redis cache
./deploy-component.sh rabbitmq    # RabbitMQ message broker
./deploy-component.sh keycloak    # Keycloak identity provider
./deploy-component.sh argocd      # ArgoCD GitOps platform
./deploy-component.sh all         # All infrastructure components
```

### Benefits of Individual Deployment

- **Faster development cycles** - Deploy only what you're working on
- **Resource efficiency** - Don't deploy unnecessary components
- **Easier debugging** - Isolate issues to specific components
- **Parallel development** - Team members can work on different components

## 📦 Components Deployed

### Infrastructure (smartcity namespace)
- **PostgreSQL** - Primary database (5Gi storage)
- **Redis** - Caching layer (1Gi storage)
- **RabbitMQ** - Message broker (2Gi storage)
- **Keycloak** - Identity and access management (1Gi storage)
- **MongoDB** - Document database (3Gi storage)
- **N8N** - Workflow automation (2Gi storage)

### ArgoCD GitOps (argocd namespace)
- **ArgoCD Server** - Web UI and API (5Gi storage)
- **Repo Server** - Git repository processing (10Gi storage)
- **Application Controller** - Application lifecycle management
- **DEX Server** - OIDC authentication
- **Redis** - Internal caching
- **Notifications Controller** - Alert system

## 🌐 Access Information

### After Deployment
Add these entries to `/etc/hosts` (replace `<MINIKUBE_IP>` with actual IP):
```
<MINIKUBE_IP> argocd.dev.smartcity.local
<MINIKUBE_IP> argocd-grpc.dev.smartcity.local
<MINIKUBE_IP> keycloak.dev.smartcity.local
```

Get Minikube IP:
```bash
minikube ip
```

### Service Access

#### ArgoCD GitOps
- **Web UI**: https://argocd.dev.smartcity.local
- **GRPC**: argocd-grpc.dev.smartcity.local:443
- **Username**: `admin`
- **Password**: `admin123` (default)

#### Infrastructure Services (Internal)
- **PostgreSQL**: `postgres-service.smartcity.svc.cluster.local:5432`
- **Redis**: `redis-service.smartcity.svc.cluster.local:6379`
- **RabbitMQ**: `rabbitmq-service.smartcity.svc.cluster.local:5672`
- **RabbitMQ Management**: `http://rabbitmq-service.smartcity.svc.cluster.local:15672`
- **Keycloak**: `http://keycloak-service.smartcity.svc.cluster.local:8080`

### Default Credentials (DEV ONLY)
```
PostgreSQL: postgres/postgres
Redis: (no auth)
RabbitMQ: admin/admin
Keycloak Admin: admin/admin
ArgoCD: admin/admin123
```

⚠️ **Change all default passwords in production!**

## 🔧 Troubleshooting

### Common Issues

#### Pods Stuck in Pending
```bash
# Check PVC status
kubectl get pvc --all-namespaces

# Check storage class
kubectl get storageclass

# Check node resources
kubectl describe nodes
```

#### ArgoCD UI Not Accessible
```bash
# Check ingress
kubectl get ingress -n argocd

# Port forward as workaround
kubectl port-forward svc/argocd-server 8080:80 -n argocd
# Access at: http://localhost:8080
```

#### Database Connection Issues
```bash
# Check PostgreSQL logs
kubectl logs -f statefulset/postgres -n smartcity

# Check service endpoints
kubectl get endpoints -n smartcity
```

### Useful Commands

```bash
# Monitor all pods
watch kubectl get pods --all-namespaces

# Check events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Resource usage
kubectl top pods --all-namespaces

# Logs
kubectl logs -f <pod-name> -n <namespace>

# Describe for detailed info
kubectl describe pod <pod-name> -n <namespace>
```

## 💾 Storage Requirements

| Component | Storage | Type | Purpose |
|-----------|---------|------|---------|
| PostgreSQL | 5Gi | RWO | Database data |
| MongoDB | 3Gi | RWO | Document storage |
| RabbitMQ | 2Gi | RWO | Message persistence |
| N8N | 2Gi | RWO | Workflow data |
| Keycloak | 1Gi | RWO | Identity data |
| Redis | 1Gi | RWO | Cache persistence |
| ArgoCD Repo | 10Gi | RWO | Git repositories |
| ArgoCD Server | 5Gi | RWO | Application data |

**Total**: ~29Gi storage required

## 🔄 Deployment Order

The scripts automatically handle the correct deployment order using Kustomize:

1. **Kustomize Processing** - Apply transformations and patches
2. **Namespaces** - Create required namespaces
3. **PVCs** - Create storage claims first
4. **Secrets & ConfigMaps** - Configuration data
5. **StatefulSets & Deployments** - Applications
6. **Services** - Internal networking
7. **Ingresses** - External access
8. **NetworkPolicies** - Security policies

### Kustomize Command Examples

```bash
# Deploy entire infrastructure
kubectl apply -k k8s/infra/dev/

# Deploy individual components
kubectl apply -k k8s/infra/dev/postgres/
kubectl apply -k k8s/infra/dev/redis/

# Preview what will be deployed
kubectl kustomize k8s/infra/dev/

# Dry-run deployment
kubectl apply -k k8s/infra/dev/ --dry-run=client
```

### View Kustomize Examples

For a comprehensive list of Kustomize commands:

```bash
./kustomize-examples.sh
```

This script shows practical examples for:
- Previewing deployments
- Individual component deployment
- Resource management
- Troubleshooting commands

## 📝 Next Steps After Deployment

### 1. Access ArgoCD
```bash
# Open in browser
https://argocd.dev.smartcity.local

# Or port forward
kubectl port-forward svc/argocd-server 8080:80 -n argocd
```

### 2. Install ArgoCD CLI (Optional)
```bash
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

# Login
argocd login argocd-grpc.dev.smartcity.local --username admin --password admin123 --insecure
```

### 3. Create GitOps Applications
- Add your application repositories
- Create ArgoCD applications
- Set up automated sync policies
- Configure notifications

### 4. Security Hardening (Production)
- Change default passwords
- Configure proper TLS certificates
- Set up RBAC policies
- Enable audit logging
- Configure backup strategies

## 🛡️ Security Notes

⚠️ **Development Environment Warning**

This setup is for **development only**:
- Uses default/weak passwords
- Self-signed certificates
- Permissive RBAC
- No network policies
- Insecure configurations

**Never use in production without proper security hardening!**

---

For more information, see the main project README or individual component documentation.
