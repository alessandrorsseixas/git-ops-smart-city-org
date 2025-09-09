#!/bin/bash

# Deploy Infrastructure for Smart City GitOps - Development Environment
# This script deploys all infrastructure components using Kustomize

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../" && pwd)"
INFRA_DIR="$PROJECT_ROOT/k8s/infra/dev"

echo "🚀 Starting Infrastructure deployment for Smart City GitOps - DEV environment..."
echo "📁 Using Kustomize structure from: $INFRA_DIR"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check cluster connectivity
echo "🔍 Checking Kubernetes cluster connectivity..."
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster"
    echo "Please check your kubectl configuration and cluster status"
    exit 1
fi

echo "✅ Connected to Kubernetes cluster"

# Deploy infrastructure using Kustomize
echo "🏗️ Deploying Infrastructure using Kustomize..."
kubectl apply -k "$INFRA_DIR"

# Wait for deployments to be ready
echo "⏳ Waiting for deployments to be ready..."
echo "   - Waiting for PostgreSQL..."
kubectl wait --for=condition=Ready --timeout=300s pod -l app=postgres -n smartcity || echo "⚠️ PostgreSQL may still be starting..."

echo "   - Waiting for MongoDB..."
kubectl wait --for=condition=Ready --timeout=300s pod -l app=mongodb -n smartcity || echo "⚠️ MongoDB may still be starting..."

echo "   - Waiting for Redis..."
kubectl wait --for=condition=Available --timeout=180s deployment/redis -n smartcity || echo "⚠️ Redis may still be starting..."

echo "   - Waiting for RabbitMQ..."
kubectl wait --for=condition=Available --timeout=180s deployment/rabbitmq -n smartcity || echo "⚠️ RabbitMQ may still be starting..."

echo "   - Waiting for Keycloak..."
kubectl wait --for=condition=Available --timeout=300s deployment/keycloak -n smartcity || echo "⚠️ Keycloak may still be starting..."

# Display deployment status
echo ""
echo "📊 Infrastructure Deployment Status:"
kubectl get pods -n smartcity
echo ""
kubectl get pvc -n smartcity
echo ""
kubectl get svc -n smartcity

echo ""
echo "🎉 Infrastructure deployment completed!"
echo ""
echo "📋 Access Information:"
echo "   PostgreSQL: postgres-service.smartcity.svc.cluster.local:5432"
echo "   MongoDB: mongodb-service.smartcity.svc.cluster.local:27017"
echo "   Redis: redis-service.smartcity.svc.cluster.local:6379"
echo "   RabbitMQ Management: http://rabbitmq-service.smartcity.svc.cluster.local:15672"
echo "   Keycloak Admin: http://keycloak-service.smartcity.svc.cluster.local:8080"
echo ""
echo "🔑 Default Credentials (DEV ONLY):"
echo "   PostgreSQL: postgres/postgres"
echo "   MongoDB: admin/admin123"
echo "   RabbitMQ: admin/admin"
echo "   Keycloak Admin: admin/admin"
echo ""
echo "📝 Next Steps:"
echo "   1. Configure Ingress for external access"
echo "   2. Set up proper DNS entries"
echo "   3. Deploy ArgoCD: ./deploy-argocd.sh"
echo ""
echo "🔍 Monitor with:"
echo "   kubectl logs -f statefulset/postgres -n smartcity"
echo "   kubectl logs -f statefulset/mongodb -n smartcity"
echo "   kubectl logs -f deployment/keycloak -n smartcity"
echo ""

echo "✅ Infrastructure deployment script completed!"
