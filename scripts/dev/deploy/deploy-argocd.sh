#!/bin/bash

# Deploy ArgoCD for Smart City GitOps - Development Environment
# This script deploys ArgoCD using Kustomize

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../" && pwd)"
INFRA_DIR="$PROJECT_ROOT/k8s/infra/dev"

echo "🚀 Starting ArgoCD deployment for Smart City GitOps - DEV environment..."
echo "📁 Using Kustomize structure from: $INFRA_DIR/argocd"

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

# Deploy ArgoCD using Kustomize
echo "🏗️ Deploying ArgoCD using Kustomize..."
kubectl apply -k "$INFRA_DIR/argocd"

# Wait for ArgoCD server to be ready
echo "⏳ Waiting for ArgoCD server to be ready..."
kubectl wait --for=condition=Available --timeout=300s deployment/argocd-server -n argocd

# Get ArgoCD admin password
echo "🔑 Retrieving ArgoCD admin password..."
ADMIN_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null || echo "admin123")

# Display access information
echo ""
echo "🎉 ArgoCD deployment completed successfully!"
echo ""
echo "📋 Access Information:"
echo "   URL: https://argocd.dev.smartcity.local"
echo "   Username: admin"
echo "   Password: $ADMIN_PASSWORD"
echo ""
echo "🌐 GRPC Access (for ArgoCD CLI):"
echo "   Server: argocd-grpc.dev.smartcity.local:443"
echo ""
echo "📝 Next Steps:"
echo "   1. Open https://argocd.dev.smartcity.local in your browser"
echo "   2. Login with admin / $ADMIN_PASSWORD"
echo "   3. Create your first GitOps application"

# Check pod status
echo "📊 Current ArgoCD Pod Status:"
kubectl get pods -n argocd

# Run health check
echo "🏥 Running health check..."
HEALTH_CHECK_SCRIPT="$SCRIPT_DIR/../health-check.sh"
if [[ -f "$HEALTH_CHECK_SCRIPT" ]]; then
    chmod +x "$HEALTH_CHECK_SCRIPT"
    "$HEALTH_CHECK_SCRIPT"
else
    echo "⚠️ Health check script not found: $HEALTH_CHECK_SCRIPT"
fi

echo "✅ ArgoCD deployment script completed!"
