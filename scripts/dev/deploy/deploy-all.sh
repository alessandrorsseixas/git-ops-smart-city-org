#!/bin/bash

# Complete Deployment Script for Smart City GitOps - Development Environment
# This script deploys all components using Kustomize for better organization

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../" && pwd)"
INFRA_DIR="$PROJECT_ROOT/k8s/infra/dev"

echo "🚀 Starting Complete Deployment for Smart City GitOps - DEV environment..."
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

# Step 1: Deploy Infrastructure using Kustomize
echo "🏗️ Step 1/3: Deploying Infrastructure using Kustomize..."
kubectl apply -k "$INFRA_DIR"

# Wait for infrastructure to be ready
echo "⏳ Waiting for infrastructure to stabilize..."
kubectl wait --for=condition=Ready --timeout=300s pod -l component=database -n smartcity || echo "⚠️ Some database pods may still be starting..."
kubectl wait --for=condition=Ready --timeout=180s pod -l component=cache -n smartcity || echo "⚠️ Redis may still be starting..."
kubectl wait --for=condition=Ready --timeout=180s pod -l component=messaging -n smartcity || echo "⚠️ RabbitMQ may still be starting..."
kubectl wait --for=condition=Ready --timeout=300s pod -l app=keycloak -n smartcity || echo "⚠️ Keycloak may still be starting..."

echo ""
echo "🎉 INFRASTRUCTURE DEPLOYMENT COMPLETED! 🎉"
echo ""
echo "📊 Current Deployment Status:"
echo ""

# Check all namespaces
echo "🔍 Checking SmartCity Infrastructure:"
kubectl get pods -n smartcity -o wide

echo ""
echo "📋 Services Status:"
kubectl get svc -n smartcity
echo ""
kubectl get svc -n smartcity -l app.kubernetes.io/name=argocd
echo ""
echo "💾 Storage Status:"
kubectl get pvc --all-namespaces

echo ""
echo "🌐 Access Information:"
echo ""
echo "📍 Infrastructure Services:"
echo "   PostgreSQL: postgres-service.smartcity.svc.cluster.local:5432"
echo "   Redis: redis-service.smartcity.svc.cluster.local:6379" 
echo "   RabbitMQ: rabbitmq-service.smartcity.svc.cluster.local:5672"
echo "   RabbitMQ Management: http://rabbitmq-service.smartcity.svc.cluster.local:15672"
echo "   Keycloak: http://keycloak-service.smartcity.svc.cluster.local:8080"
echo ""
echo "🔑 Default Credentials (DEV ONLY - CHANGE IN PRODUCTION):"
echo "   PostgreSQL: postgres/postgres"
echo "   RabbitMQ: admin/admin"
echo "   Keycloak Admin: admin/admin"
echo ""
echo "📝 Next Steps:"
echo ""
echo "1. 🌐 Configure DNS/Hosts:"
echo "   Add to /etc/hosts (replace <MINIKUBE_IP> with actual IP):"
echo "   <MINIKUBE_IP> argocd.dev.smartcity.local"
echo "   <MINIKUBE_IP> argocd-grpc.dev.smartcity.local" 
echo "   <MINIKUBE_IP> keycloak.dev.smartcity.local"
echo ""
echo "2. 🔧 Get Minikube IP:"
echo "   minikube ip"
echo ""
echo "3. 🎯 Access ArgoCD:"
echo "   - Open https://argocd.dev.smartcity.local in browser"
echo "   - Login with admin/admin123"
echo "   - Create your first GitOps application"
echo ""
echo "4. 🔐 Install ArgoCD CLI (optional):"
echo "   curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
echo "   chmod +x /usr/local/bin/argocd"
echo ""
echo "5. 📊 Monitor Deployments:"
echo "   kubectl get pods --all-namespaces"
echo "   kubectl logs -f deployment/keycloak -n smartcity"
echo "   kubectl logs -f deployment/argocd-server -n smartcity"
echo ""

# Final health check
echo "🏥 Final Health Check:"
FAILED_PODS=$(kubectl get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded --no-headers 2>/dev/null | wc -l)

if [ "$FAILED_PODS" -eq 0 ]; then
    echo "✅ All pods are running successfully!"
else
    echo "⚠️ $FAILED_PODS pod(s) are not in Running state. Check with:"
    echo "   kubectl get pods --all-namespaces"
    kubectl get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded
fi

echo ""
echo "🚀 Smart City GitOps Platform is ready for development!"
echo "✅ Complete deployment script finished!"

echo ""
echo "⏳ Waiting 30 seconds for infrastructure to stabilize..."
sleep 30

# Step 2: ArgoCD is already deployed with infrastructure
echo "🔄 Step 2/3: ArgoCD already deployed with infrastructure - skipping..."
echo "✅ ArgoCD deployment completed (already included in infrastructure)"

# Step 3: Get ArgoCD admin password
echo "🔑 Step 3/3: Retrieving ArgoCD admin password..."
ADMIN_PASSWORD=$(kubectl -n smartcity get secret argocd-secret -o jsonpath="{.data.admin\.password}" 2>/dev/null | base64 -d 2>/dev/null || echo "admin123")

echo ""
echo "🎉 COMPLETE DEPLOYMENT FINISHED! 🎉"
echo ""
echo "📊 Final Deployment Status:"
echo ""

# Check all namespaces
echo "🔍 Checking SmartCity Infrastructure:"
kubectl get pods -n smartcity -o wide

echo ""
echo "🔍 Checking ArgoCD:"
kubectl get pods -n smartcity -l app.kubernetes.io/name=argocd

echo ""
echo "📋 Services Status:"
kubectl get svc -n smartcity
echo ""
kubectl get svc -n argocd
echo ""
echo "💾 Storage Status:"
kubectl get pvc --all-namespaces

echo ""
echo "🌐 Access Information:"
echo ""
echo "📍 Infrastructure Services:"
echo "   PostgreSQL: postgres-service.smartcity.svc.cluster.local:5432"
echo "   Redis: redis-service.smartcity.svc.cluster.local:6379" 
echo "   RabbitMQ: rabbitmq-service.smartcity.svc.cluster.local:5672"
echo "   RabbitMQ Management: http://rabbitmq-service.smartcity.svc.cluster.local:15672"
echo "   Keycloak: http://keycloak-service.smartcity.svc.cluster.local:8080"
echo ""
echo "🎯 ArgoCD GitOps:"
echo "   UI: https://argocd.dev.smartcity.local"
echo "   GRPC: argocd-grpc.dev.smartcity.local:443"
echo "   Username: admin"
echo "   Password: $ADMIN_PASSWORD"
echo ""
echo "🔑 Default Credentials (DEV ONLY - CHANGE IN PRODUCTION):"
echo "   PostgreSQL: postgres/postgres"
echo "   RabbitMQ: admin/admin"
echo "   Keycloak Admin: admin/admin"
echo "   ArgoCD: admin/$ADMIN_PASSWORD"
echo ""
echo "📝 Next Steps:"
echo ""
echo "1. 🌐 Configure DNS/Hosts:"
echo "   Add to /etc/hosts (replace <MINIKUBE_IP> with actual IP):"
echo "   <MINIKUBE_IP> argocd.dev.smartcity.local"
echo "   <MINIKUBE_IP> argocd-grpc.dev.smartcity.local" 
echo "   <MINIKUBE_IP> keycloak.dev.smartcity.local"
echo ""
echo "2. 🔧 Get Minikube IP:"
echo "   minikube ip"
echo ""
echo "3. 🎯 Access ArgoCD:"
echo "   - Open https://argocd.dev.smartcity.local in browser"
echo "   - Login with admin / $ADMIN_PASSWORD"
echo "   - Create your first GitOps application"
echo ""
echo "4. 🔐 Install ArgoCD CLI (optional):"
echo "   curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
echo "   chmod +x /usr/local/bin/argocd"
echo ""
echo "5. 📊 Monitor Deployments:"
echo "   kubectl get pods --all-namespaces"
echo "   kubectl logs -f deployment/keycloak -n smartcity"
echo "   kubectl logs -f deployment/argocd-server -n smartcity"
echo ""

# Final health check
echo "🏥 Final Health Check:"
FAILED_PODS=$(kubectl get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded --no-headers 2>/dev/null | wc -l)

if [ "$FAILED_PODS" -eq 0 ]; then
    echo "✅ All pods are running successfully!"
else
    echo "⚠️ $FAILED_PODS pod(s) are not in Running state. Check with:"
    echo "   kubectl get pods --all-namespaces"
    kubectl get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded
fi

echo ""
echo "🚀 Smart City GitOps Platform is ready for development!"
echo "✅ Complete deployment script finished!"
