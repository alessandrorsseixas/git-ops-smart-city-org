# Smart City GitOps Platform

A Kubernetes-based GitOps platform for Smart City applications with infrastructure automation and application deployment.

## 🎯 Overview

This repository provides GitOps configuration for Smart City applications, featuring:

- **Application deployments** using Kubernetes manifests and Kustomize
- **Infrastructure as Code** with automated deployment scripts
- **Microservices architecture** for House Control and other Smart City services
- **Development environment** setup with Minikube support
- **GitOps workflows** ready for ArgoCD integration

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Applications  │    │ Infrastructure   │    │    GitOps      │
│   (Microservices│◄──►│   Components     │◄──►│   Deployment   │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ • House Control │    │ • PostgreSQL    │    │ • Kustomize     │
│ • Smart City    │    │ • Redis         │    │ • ArgoCD Ready  │
│   Services      │    │ • RabbitMQ      │    │ • Helm Charts   │
│ • APIs          │    │ • Prometheus    │    │ • Auto Deploy   │
│ • Web Apps      │    │ • Ingress NGINX │    │ • Monitoring    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📦 Components

### Applications (house-control namespace)
- **House Control** - Smart home management microservice with Spring Boot
- **ConfigMap/Secret** - Configuration management with environment variables
- **Ingress** - External access via NGINX Ingress Controller
- **HPA** - Horizontal Pod Autoscaler for automatic scaling
- **Service** - Internal service discovery and load balancing

### Infrastructure (infrastructure namespace)
- **PostgreSQL** - Primary relational database with Helm deployment
- **Redis** - High-performance caching layer with persistence
- **RabbitMQ** - Message broker for event-driven architecture
- **Prometheus** - Monitoring and metrics collection
- **NGINX Ingress** - Load balancer and reverse proxy

## 🚀 Quick Start

### Prerequisites

- **Kubernetes cluster** (Minikube recommended for development)
- **kubectl** configured and connected to your cluster
- **Helm 3.x** for infrastructure components
- **NGINX Ingress Controller** installed in your cluster
- **Minimum resources**: 2 CPU cores, 4GB RAM, 20GB storage

### Deploy Infrastructure

```bash
# Clone the repository
git clone https://github.com/alessandrorsseixas/git-ops-smart-city-org.git
cd git-ops-smart-city-org

# Deploy infrastructure components (PostgreSQL, Redis, RabbitMQ, Prometheus)
cd k8s/infra/dev
./deploy-all-infrastructure.sh

# Configure /etc/hosts for local access
echo "$(minikube ip) house-control.dev.smartcity.local" | sudo tee -a /etc/hosts
echo "$(minikube ip) postgres.dev.smartcity.local" | sudo tee -a /etc/hosts
echo "$(minikube ip) redis.dev.smartcity.local" | sudo tee -a /etc/hosts
echo "$(minikube ip) rabbitmq.dev.smartcity.local" | sudo tee -a /etc/hosts
echo "$(minikube ip) prometheus.dev.smartcity.local" | sudo tee -a /etc/hosts
```

### Deploy Applications

```bash
# Deploy House Control application
cd gitops/dev/house-control
kubectl apply -k .

# Or use the deployment script
./deploy.sh
```

## 🌐 Access Information

### Application Services
- **House Control**: http://house-control.dev.smartcity.local
  - Health Check: `/actuator/health`
  - Metrics: `/actuator/metrics`
  - Info: `/actuator/info`

### Infrastructure Services (via Ingress)
- **PostgreSQL**: postgres.dev.smartcity.local:5432
- **Redis**: redis.dev.smartcity.local:6379
- **RabbitMQ Management**: http://rabbitmq.dev.smartcity.local:15672
- **Prometheus**: http://prometheus.dev.smartcity.local:9090

### Default Credentials (Development Only)
```
PostgreSQL: smartcity/smartcity123
Redis: redis123
RabbitMQ: admin/admin123
```

⚠️ **Important**: These are development credentials. Change them in production!

## 📁 Project Structure

```
git-ops-smart-city-org/
│──── dev/                        # Development environment
│       └── house-control/        # House Control microservice
│           ├── kustomization.yaml
│           ├── house-control-namespace.yaml
│           ├── house-control-config-map.yaml
│           ├── house-control-secret.yaml
│           ├── house-control-deployment.yaml
│           ├── house-control-service.yaml
│           ├── house-control-ingress.yaml
│           ├── house-control-hpa.yaml
│           ├── deploy.sh         # Deployment script
│           ├── validate-ports.sh # Port validation
│           └── README.md         # Application documentation
│
└── README.md                     # This file
```

## 🔧 Configuration Management

This project uses **Kustomize** for application configuration and **Helm** for infrastructure components:

### Application Configuration (Kustomize)
- **Environment-based overlays** - Development, staging, production
- **ConfigMap/Secret pattern** - Consistent configuration management
- **Resource customization** - Component-specific settings
- **Label standardization** - Consistent labeling across resources

### Infrastructure Configuration (Helm)
- **Values-based customization** - Environment-specific values files
- **Chart versioning** - Pinned versions for reproducible deployments
- **Dependency management** - Automated dependency resolution
- **Upgrade strategies** - Rolling updates with health checks

### Key Configuration Features
- **Standardized patterns** - ConfigMap and Secret follow same structure
- **Environment variables** - Twelve-factor app compliance
- **Service discovery** - DNS-based service communication
- **Health monitoring** - Comprehensive health check configuration

## 📊 Monitoring & Observability

### Application Monitoring
- **Spring Boot Actuator** - Built-in health checks and metrics
- **Prometheus metrics** - Application metrics collection
- **Custom metrics** - Business logic monitoring
- **Distributed tracing** - Request flow tracking

### Infrastructure Monitoring
- **Resource monitoring** - CPU, memory, disk usage
- **Service health** - Database and messaging service status
- **Network monitoring** - Inter-service communication
- **Storage monitoring** - Persistent volume usage

### Operational Features
- **Health endpoints** - `/actuator/health` for all services
- **Metrics endpoints** - `/actuator/metrics` for detailed metrics
- **Log aggregation** - Structured JSON logging
- **Alert configuration** - Prometheus alerting rules

## 🔒 Security Features

### Application Security
- **Non-root containers** - All applications run as non-privileged users
- **Resource limits** - CPU and memory limits to prevent resource exhaustion
- **Health checks** - Automatic restart of unhealthy containers
- **Configuration security** - Sensitive data stored in Kubernetes Secrets

### Network Security
- **Ingress-controlled access** - External access only through NGINX Ingress
- **Service mesh ready** - Prepared for service mesh integration
- **Namespace isolation** - Applications isolated in separate namespaces
- **Port security** - Consistent port configuration validation

### Infrastructure Security
- **Database access control** - User-based access control for databases
- **Secret management** - Base64-encoded secrets in Kubernetes
- **TLS/SSL ready** - HTTPS endpoints configuration
- **Backup security** - Secure backup and restore procedures

## �️ Troubleshooting

### Common Issues

#### Pod CrashLoopBackOff
```bash
# Check pod logs
kubectl logs -n house-control -l app=house-control-container --previous

# Check pod events
kubectl describe pod -n house-control -l app=house-control-container

# Verify configuration
kubectl exec -n house-control -it deployment/house-control -- env | grep SPRING
```

#### HPA Issues (Metrics Server)
```bash
# Install Metrics Server for Minikube
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Patch for Minikube (insecure TLS)
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

# Verify metrics
kubectl top pods -n house-control
```

#### Ingress Issues
```bash
# Check Ingress Controller
kubectl get pods -n ingress-nginx

# Verify Ingress configuration
kubectl describe ingress -n house-control house-control-ingress

# Test /etc/hosts configuration
ping house-control.dev.smartcity.local
```

#### Database Connection Issues
```bash
# Test database connectivity
kubectl exec -n house-control -it deployment/house-control -- nc -zv postgres.infrastructure.svc.cluster.local 5432

# Check database service
kubectl get svc -n infrastructure

# Verify credentials
kubectl get secret -n house-control house-control-secret -o yaml
```

## 🚀 Deployment Strategies

### GitOps Workflow
- **Git-based deployments** - All changes through Git commits
- **ArgoCD integration** - Ready for GitOps controller setup
- **Branch-based environments** - Different branches for different environments
- **Pull request reviews** - Code review process for deployments

### Kubernetes Deployments
- **Rolling updates** - Zero-downtime application updates
- **Health check integration** - Automatic rollback on health check failures
- **Resource management** - CPU and memory limits with HPA
- **Namespace isolation** - Environment separation through namespaces

### Infrastructure Deployment
- **Helm-based infrastructure** - Infrastructure as code with Helm charts
- **Version pinning** - Specific versions for reproducible deployments
- **Automated scripts** - One-command infrastructure deployment
- **Dependency management** - Proper service startup order

## 🧪 Testing & Validation

### Port Validation
```bash
# Validate port consistency across all manifests
cd gitops/dev/house-control
./validate-ports.sh
```

### Application Testing
```bash
# Test application health
curl http://house-control.dev.smartcity.local/actuator/health

# Test application metrics
curl http://house-control.dev.smartcity.local/actuator/metrics

# Load testing for HPA
kubectl run load-generator --image=busybox --restart=Never --rm -i --tty -- /bin/sh
```

### Infrastructure Testing
```bash
# Test database connectivity
kubectl exec -n house-control -it deployment/house-control -- nc -zv postgres.infrastructure.svc.cluster.local 5432

# Test Redis connectivity
kubectl exec -n house-control -it deployment/house-control -- nc -zv redis.infrastructure.svc.cluster.local 6379

# Test RabbitMQ connectivity
kubectl exec -n house-control -it deployment/house-control -- nc -zv rabbitmq.infrastructure.svc.cluster.local 5672
```

### Deployment Validation
```bash
# Validate Kustomize configuration
kubectl kustomize gitops/dev/house-control

# Dry-run deployment
kubectl apply -k gitops/dev/house-control --dry-run=client
```

## 📚 Documentation
## 📚 Documentation

### Application Documentation
- **[House Control Application](gitops/dev/house-control/README.md)** - Complete application guide
- **Configuration patterns** - ConfigMap and Secret management
- **Deployment procedures** - Step-by-step deployment guides
- **Troubleshooting guides** - Common issues and solutions

### Infrastructure Documentation
- **Component deployment** - Individual infrastructure components
- **Network configuration** - Ingress and service setup
- **Security configuration** - Access control and secrets
- **Monitoring setup** - Prometheus and health checks

### Operational Guides
- **Port validation** - Ensuring consistent port configuration
- **Health monitoring** - Application and infrastructure health
- **Scaling procedures** - Manual and automatic scaling
- **Update procedures** - Rolling updates and rollbacks
## 🤝 Contributing

### Development Workflow
1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/new-service`)
3. **Make** your changes following the established patterns
4. **Test** thoroughly using provided validation scripts
5. **Submit** a pull request with detailed description

### Code Standards
- **Kustomize best practices** - Follow established Kustomize patterns
- **Consistent configuration** - Use ConfigMap/Secret patterns
- **Documentation** - Update README files for all changes
- **Testing** - Include validation scripts for new components
- **Security** - Follow security best practices

### Adding New Services
1. **Create service directory** in `gitops/dev/`
2. **Follow naming conventions** - Use `service-name-resource-type.yaml`
3. **Include all resources** - Namespace, ConfigMap, Secret, Deployment, Service, Ingress
4. **Add to kustomization.yaml** - Include all resources
5. **Create deployment script** - Include validation and health checks
6. **Update documentation** - Add README with service-specific information

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

### Getting Help
- **Documentation** - Check component-specific README files
- **Issues** - Open GitHub Issues for bugs and feature requests
- **Discussions** - Use GitHub Discussions for questions and ideas
- **Validation** - Use provided scripts for troubleshooting

### Useful Commands
```bash
# Quick health check for all services
kubectl get pods --all-namespaces

# Check service connectivity
kubectl get svc --all-namespaces

# Validate Kustomize configuration
find gitops/ -name kustomization.yaml -exec dirname {} \; | xargs -I {} sh -c 'echo "=== {} ===" && kubectl kustomize {}'

# Port validation
find gitops/ -name validate-ports.sh -exec {} \;
```

### Common Resources
- **Kubernetes Documentation** - https://kubernetes.io/docs/
- **Kustomize Documentation** - https://kustomize.io/
- **Helm Documentation** - https://helm.sh/docs/
- **NGINX Ingress** - https://kubernetes.github.io/ingress-nginx/

---

**Happy deploying with GitOps! 🚀**