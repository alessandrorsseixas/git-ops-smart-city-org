# Smart City GitOps Platform

A complete, production-ready Kubernetes infrastructure for Smart City applications using GitOps principles with ArgoCD.

## 🎯 Overview

This repository provides a comprehensive infrastructure setup for Smart City applications, featuring:

- **Multi-database support** (PostgreSQL, MongoDB, Redis)
- **Message broker** (RabbitMQ) for event-driven architecture
- **Identity management** (Keycloak) with OAuth2/OIDC
- **GitOps deployment** (ArgoCD) for continuous delivery
- **Production-ready configurations** with security, monitoring, and backups
- **Kustomize-based** organization for multi-environment deployments

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Applications  │    │ Infrastructure   │    │    ArgoCD      │
│   (GitOps)      │◄──►│   Components     │◄──►│  GitOps Platform│
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ • Smart City    │    │ • PostgreSQL    │    │ • Web UI        │
│   Services      │    │ • MongoDB       │    │ • API Server    │
│ • Microservices │    │ • Redis         │    │ • Repo Server   │
│ • APIs          │    │ • RabbitMQ      │    │ • Controller    │
│ • Web Apps      │    │ • Keycloak      │    │ • Notifications │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📦 Components

### Infrastructure (smartcity namespace)
- **PostgreSQL** - Primary relational database with advanced configuration
- **MongoDB** - Document database with replica set preparation
- **Redis** - High-performance caching layer with persistence
- **RabbitMQ** - Message broker with management UI and clustering
- **Keycloak** - Identity and access management platform
- **N8N** - Workflow automation and integration platform

### GitOps Platform (argocd namespace)
- **ArgoCD Server** - Web-based UI for GitOps operations
- **Repo Server** - Processes Git repositories and generates manifests
- **Application Controller** - Manages application lifecycle
- **DEX Server** - OIDC authentication provider
- **Notifications** - Alert and notification system

## 🚀 Quick Start

### Prerequisites

- **Kubernetes cluster** (Minikube, K3s, EKS, etc.)
- **kubectl** configured and connected to your cluster
- **Minimum resources**: 2 CPU cores, 4GB RAM, 30GB storage
- **Storage provisioner** (default StorageClass available)

### One-Command Deployment

```bash
# Clone the repository
git clone <repository-url>
cd git-ops-smart-city-org

# Deploy everything
./scripts/dev/deploy/deploy-all.sh
```

### Step-by-Step Deployment

```bash
# 1. Deploy storage
./scripts/dev/deploy/deploy-pvcs.sh

# 2. Deploy infrastructure
./scripts/dev/deploy/deploy-infra.sh

# 3. Deploy ArgoCD
./scripts/dev/deploy/deploy-argocd.sh
```

### Individual Component Deployment

```bash
# Deploy specific components
./scripts/dev/deploy/deploy-component.sh postgres
./scripts/dev/deploy/deploy-component.sh redis
./scripts/dev/deploy/deploy-component.sh argocd
```

## 🌐 Access Information

### ArgoCD GitOps Platform
- **URL**: https://argocd.dev.smartcity.local
- **Username**: `admin`
- **Password**: Retrieved from deployment output
- **GRPC**: argocd-grpc.dev.smartcity.local:443

### Infrastructure Services (Internal)
- **PostgreSQL**: postgres-service.smartcity.svc.cluster.local:5432
- **MongoDB**: mongodb-service.smartcity.svc.cluster.local:27017
- **Redis**: redis-service.smartcity.svc.cluster.local:6379
- **RabbitMQ**: rabbitmq-service.smartcity.svc.cluster.local:5672
- **RabbitMQ Management**: http://rabbitmq-service.smartcity.svc.cluster.local:15672
- **Keycloak**: http://keycloak-service.smartcity.svc.cluster.local:8080

### Default Credentials (Development Only)
```
PostgreSQL: postgres/postgres
MongoDB: admin/admin123
Redis: (no authentication)
RabbitMQ: admin/admin
Keycloak: admin/admin
ArgoCD: admin/[generated-password]
```

⚠️ **Important**: Change all default passwords in production!

## 📁 Project Structure

```
git-ops-smart-city-org/
├── k8s/                          # Kubernetes manifests
│   └── infra/
│       └── dev/                  # Development environment
│           ├── kustomization.yaml # Main Kustomize config
│           ├── postgres/         # PostgreSQL component
│           ├── mongo/            # MongoDB component
│           ├── redis/            # Redis component
│           ├── rabbitmq/         # RabbitMQ component
│           ├── keycloack/        # Keycloak component
│           └── argocd/           # ArgoCD component
├── scripts/
│   └── dev/
│       ├── deploy/               # Deployment scripts
│       │   ├── deploy-all.sh     # Complete deployment
│       │   ├── deploy-infra.sh   # Infrastructure only
│       │   ├── deploy-argocd.sh  # ArgoCD only
│       │   ├── deploy-pvcs.sh    # Storage only
│       │   ├── deploy-component.sh # Individual components
│       │   └── kustomize-examples.sh # Kustomize examples
│       └── install/              # Installation helpers
└── README.md                     # This file
```

## 🔧 Configuration Management

This project uses **Kustomize** for configuration management, providing:

### Benefits
- **Hierarchical organization** - Components in separate directories
- **Environment overlays** - Easy dev/staging/production switching
- **DRY principles** - Shared configurations across components
- **Version control** - All configurations tracked in Git
- **Modular deployments** - Deploy individual components or entire stacks

### Key Features Used
- **Common Labels** - Consistent labeling across all resources
- **Image Transformations** - Environment-specific image versions
- **ConfigMap Generators** - Dynamic configuration generation
- **Strategic Merges** - Component-specific customizations
- **Namespace Management** - Automatic namespace assignment

## 📊 Monitoring & Observability

### Health Checks
All components include comprehensive health checks:
- **Readiness probes** - Ensure services are ready to receive traffic
- **Liveness probes** - Restart unhealthy containers
- **Startup probes** - Handle slow-starting applications

### Logging
- **Structured logging** - JSON format for better parsing
- **Log rotation** - Automatic log management
- **Centralized logging** - Ready for log aggregation systems

### Metrics
- **Prometheus endpoints** - Built-in metrics for monitoring
- **Custom metrics** - Application-specific monitoring
- **Resource monitoring** - CPU, memory, disk usage

## 🔒 Security Features

### Network Security
- **Network Policies** - Control traffic between pods
- **Service Mesh ready** - Istio/Linkerd integration points
- **TLS encryption** - HTTPS for all external services

### Access Control
- **RBAC** - Role-based access control for Kubernetes
- **ArgoCD RBAC** - Fine-grained GitOps permissions
- **Keycloak integration** - Centralized identity management

### Secrets Management
- **Kubernetes Secrets** - Encrypted sensitive data
- **External secret management** - Ready for HashiCorp Vault
- **Rotation policies** - Automated secret rotation

## 💾 Backup & Recovery

### Automated Backups
- **PostgreSQL** - Daily backups with point-in-time recovery
- **MongoDB** - Scheduled backups with retention policies
- **Redis** - RDB snapshots with configurable intervals
- **RabbitMQ** - Message persistence and queue mirroring

### Backup Storage
- **PVC-based** - Persistent storage for backup data
- **External storage** - Ready for S3, GCS, Azure Blob
- **Compression** - Optimized storage usage

### Recovery Procedures
- **Automated restore** - One-command recovery scripts
- **Point-in-time recovery** - Restore to specific timestamps
- **Cross-region backup** - Disaster recovery capabilities

## 🚀 Deployment Strategies

### Blue-Green Deployment
- **Zero-downtime updates** - Switch between blue and green environments
- **Automated rollback** - Instant rollback on failures
- **Traffic shifting** - Gradual traffic migration

### Canary Deployment
- **Percentage-based rollout** - Deploy to percentage of users
- **Automated analysis** - Monitor metrics during canary
- **Automatic promotion** - Promote based on success criteria

### GitOps Workflows
- **Pull Request deployments** - Deploy from Git branches
- **Environment promotion** - Automated dev → staging → prod
- **Approval workflows** - Manual approval for production

## 🧪 Testing

### Component Testing
- **Unit tests** - Individual component validation
- **Integration tests** - End-to-end workflow testing
- **Performance tests** - Load and stress testing

### Deployment Testing
- **Dry-run deployments** - Validate manifests without applying
- **Canary testing** - Test deployments on subset of infrastructure
- **Rollback testing** - Ensure rollback procedures work

## 📚 Documentation

### Component Documentation
Each component includes comprehensive documentation:
- **Architecture decisions** - Why certain choices were made
- **Configuration options** - Available customization parameters
- **Troubleshooting guides** - Common issues and solutions
- **Performance tuning** - Optimization recommendations

### Operational Runbooks
- **Deployment procedures** - Step-by-step deployment guides
- **Incident response** - Handling production incidents
- **Maintenance tasks** - Regular maintenance procedures
- **Upgrade procedures** - Version upgrade processes

## 🤝 Contributing

### Development Workflow
1. **Fork** the repository
2. **Create** a feature branch
3. **Make** your changes
4. **Test** thoroughly
5. **Submit** a pull request

### Code Standards
- **Kustomize best practices** - Follow Kustomize conventions
- **Security first** - Implement security measures
- **Documentation** - Update docs for all changes
- **Testing** - Include tests for new features

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

### Issues
- **Bug reports** - Use GitHub Issues
- **Feature requests** - Use GitHub Discussions
- **Security issues** - Contact maintainers directly

### Community
- **Discussions** - GitHub Discussions for questions
- **Wiki** - Community-contributed documentation
- **Slack/Teams** - Community chat channels

---

**Happy deploying! 🚀**