#!/bin/bash

# Complete deployment for Smart City GitOps - Development Environment
# This script orchestrates the complete deployment: PVCs -> Infrastructure -> ArgoCD

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Starting COMPLETE deployment for Smart City GitOps - DEV environment..."
echo "   This will deploy: PVCs -> Infrastructure -> ArgoCD"
echo ""

# Confirmation prompt
read -p "🤔 Do you want to proceed with the complete deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled by user"
    exit 0
fi

echo "📋 Deployment Plan:"
echo "   1. 💾 Deploy Persistent Volume Claims"
echo "   2. 🏗️  Deploy Infrastructure (PostgreSQL, Redis, RabbitMQ, Keycloak)"
echo "   3. 🎯 Deploy ArgoCD GitOps"
echo ""

# Step 1: Deploy PVCs
echo "🔄 Step 1/3: Deploying Persistent Volume Claims..."
if [ -f "$SCRIPT_DIR/deploy-pvcs.sh" ]; then
    bash "$SCRIPT_DIR/deploy-pvcs.sh"
    echo "✅ PVCs deployment completed"
else
    echo "❌ deploy-pvcs.sh not found!"
    exit 1
fi

echo ""
echo "⏳ Waiting 10 seconds for PVCs to stabilize..."
sleep 10

# Step 2: Deploy Infrastructure
echo "🔄 Step 2/3: Deploying Infrastructure..."
if [ -f "$SCRIPT_DIR/deploy-infra.sh" ]; then
    bash "$SCRIPT_DIR/deploy-infra.sh"
    echo "✅ Infrastructure deployment completed"
else
    echo "❌ deploy-infra.sh not found!"
    exit 1
fi

echo ""
echo "⏳ Waiting 30 seconds for infrastructure to stabilize..."
sleep 30

# Step 3: Deploy ArgoCD
echo "🔄 Step 3/3: Deploying ArgoCD..."
if [ -f "$SCRIPT_DIR/deploy-argocd.sh" ]; then
    bash "$SCRIPT_DIR/deploy-argocd.sh"
    echo "✅ ArgoCD deployment completed"
else
    echo "❌ deploy-argocd.sh not found!"
    exit 1
fi

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
kubectl get pods -n argocd -o wide

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
echo "   Password: admin123 (or check ArgoCD deployment output)"
echo ""
echo "🔑 Default Credentials (DEV ONLY - CHANGE IN PRODUCTION):"
echo "   PostgreSQL: postgres/postgres"
echo "   RabbitMQ: admin/admin"
echo "   Keycloak Admin: admin/admin"
echo "   ArgoCD: admin/admin123"
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
echo "   kubectl logs -f deployment/argocd-server -n argocd"
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
