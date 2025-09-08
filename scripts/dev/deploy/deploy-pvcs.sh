#!/bin/bash

# Deploy PVCs for Smart City GitOps - Development Environment
# This script creates all Persistent Volume Claims needed for the infrastructure

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../" && pwd)"
INFRA_DIR="$PROJECT_ROOT/k8s/infra/dev"

echo "💾 Starting PVC deployment for Smart City GitOps - DEV environment..."

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

# Create namespace if it doesn't exist
echo "📦 Creating/Checking smartcity namespace..."
kubectl create namespace smartcity --dry-run=client -o yaml | kubectl apply -f -

# Create namespace for ArgoCD if it doesn't exist
echo "📦 Creating/Checking argocd namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

echo "💾 Creating Persistent Volume Claims..."

# Infrastructure PVCs
echo "   - PostgreSQL PVC (5Gi)..."
kubectl apply -f "$INFRA_DIR/postgres-pvc.yaml"

echo "   - MongoDB PVC (3Gi)..."
kubectl apply -f "$INFRA_DIR/mongodb-pvc.yaml"

echo "   - Redis PVC (1Gi)..."
kubectl apply -f "$INFRA_DIR/redis-pvc.yaml"

echo "   - RabbitMQ PVC (2Gi)..."
kubectl apply -f "$INFRA_DIR/rabbitmq-pvc.yaml"

echo "   - Keycloak PVC (1Gi)..."
kubectl apply -f "$INFRA_DIR/keycloak-pvc.yaml"

echo "   - N8N PVC (2Gi)..."
kubectl apply -f "$INFRA_DIR/n8n-pvc.yaml"

# ArgoCD PVCs
echo "   - ArgoCD PVCs (10Gi + 5Gi)..."
kubectl apply -f "$INFRA_DIR/argocd-pvc.yaml"

# Wait for PVCs to be created
echo "⏳ Waiting for PVCs to be bound..."
echo "   Note: This may take a few moments depending on your storage provisioner..."

# Check PVC status in smartcity namespace
echo ""
echo "📊 PVC Status in smartcity namespace:"
kubectl get pvc -n smartcity

# Check PVC status in argocd namespace
echo ""
echo "📊 PVC Status in argocd namespace:"
kubectl get pvc -n argocd

# Wait for specific PVCs to be bound (with timeout)
echo ""
echo "⏳ Checking PVC binding status..."

PVCS_SMARTCITY=("postgres-pvc" "mongodb-pvc" "redis-pvc" "rabbitmq-pvc" "keycloak-pvc" "n8n-pvc")
PVCS_ARGOCD=("argocd-repo-server-pvc" "argocd-server-pvc")

for pvc in "${PVCS_SMARTCITY[@]}"; do
    echo "   Checking $pvc in smartcity namespace..."
    kubectl wait --for=condition=Bound --timeout=30s pvc/$pvc -n smartcity || echo "   ⚠️ $pvc is still pending..."
done

for pvc in "${PVCS_ARGOCD[@]}"; do
    echo "   Checking $pvc in argocd namespace..."
    kubectl wait --for=condition=Bound --timeout=30s pvc/$pvc -n argocd || echo "   ⚠️ $pvc is still pending..."
done

echo ""
echo "📋 Storage Summary:"
echo "   Infrastructure Storage: ~14Gi total"
echo "   - PostgreSQL: 5Gi"
echo "   - MongoDB: 3Gi" 
echo "   - RabbitMQ: 2Gi"
echo "   - N8N: 2Gi"
echo "   - Redis: 1Gi"
echo "   - Keycloak: 1Gi"
echo ""
echo "   ArgoCD Storage: 15Gi total"
echo "   - ArgoCD Repo Server: 10Gi"
echo "   - ArgoCD Server: 5Gi"
echo ""
echo "   Total Storage Required: ~29Gi"
echo ""

# Final status check
echo "📊 Final PVC Status:"
echo ""
echo "SmartCity namespace:"
kubectl get pvc -n smartcity -o wide
echo ""
echo "ArgoCD namespace:"
kubectl get pvc -n argocd -o wide

echo ""
echo "🎉 PVC deployment completed!"
echo ""
echo "📝 Next Steps:"
echo "   1. Verify all PVCs are bound: kubectl get pvc --all-namespaces"
echo "   2. Deploy infrastructure: ./deploy-infra.sh"
echo "   3. Deploy ArgoCD: ./deploy-argocd.sh"
echo ""
echo "⚠️ Note: If PVCs are stuck in 'Pending' state:"
echo "   - Check storage provisioner: kubectl get storageclass"
echo "   - Check available disk space on nodes"
echo "   - For Minikube: ensure sufficient disk space allocated"
echo ""

echo "✅ PVC deployment script completed!"
