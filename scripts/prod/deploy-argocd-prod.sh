#!/bin/bash

# Deploy ArgoCD for Smart City GitOps - Production Environment
# This script deploys ArgoCD with production-ready configurations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../" && pwd)"
PROD_DIR="$PROJECT_ROOT/k8s/infra/prod"

echo "🚀 Starting ArgoCD deployment for Smart City GitOps - PRODUCTION environment..."

# Production safety checks
echo "⚠️ PRODUCTION DEPLOYMENT WARNING ⚠️"
echo "   This will deploy ArgoCD to a PRODUCTION environment"
echo "   Ensure you have:"
echo "   - Proper TLS certificates"
echo "   - Secure passwords configured"
echo "   - Network policies in place"
echo "   - Backup strategies configured"
echo ""

read -p "🤔 Are you sure you want to proceed with PRODUCTION deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Production deployment cancelled by user"
    exit 0
fi

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

# Verify we're connected to production cluster
echo "🏷️ Verifying cluster context..."
CURRENT_CONTEXT=$(kubectl config current-context)
echo "   Current context: $CURRENT_CONTEXT"

if [[ ! $CURRENT_CONTEXT =~ (prod|production) ]]; then
    echo "⚠️ WARNING: Context doesn't seem to be production"
    read -p "   Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Deployment cancelled - verify cluster context"
        exit 1
    fi
fi

echo "✅ Connected to Kubernetes cluster"

# Check if production manifests exist
if [ ! -d "$PROD_DIR" ]; then
    echo "❌ Production manifests directory not found: $PROD_DIR"
    echo "Please create production manifests first"
    exit 1
fi

# Create ArgoCD namespace with production labels
echo "📦 Creating ArgoCD namespace with production configuration..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: argocd
  labels:
    name: argocd
    environment: production
    managed-by: smart-city-gitops
  annotations:
    deployment.kubernetes.io/revision: "$(date +%s)"
EOF

# Wait for namespace to be ready
echo "⏳ Waiting for namespace to be ready..."
kubectl wait --for=condition=Ready --timeout=30s namespace/argocd || true

# Apply production ArgoCD manifests in order
echo "🔧 Applying ArgoCD production configurations..."

# Check if production files exist and apply them
REQUIRED_FILES=(
    "argocd-configmap.yaml"
    "argocd-secret.yaml"
    "argocd-pvc.yaml"
    "argocd-rbac.yaml"
    "argocd-deployment.yaml"
    "argocd-service.yaml"
    "argocd-ingress.yaml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$PROD_DIR/$file" ]; then
        echo "   Applying $file..."
        kubectl apply -f "$PROD_DIR/$file"
    else
        echo "⚠️ Production file not found: $PROD_DIR/$file"
        echo "   Using development version as fallback..."
        DEV_FILE="$PROJECT_ROOT/k8s/infra/dev/$file"
        if [ -f "$DEV_FILE" ]; then
            kubectl apply -f "$DEV_FILE"
        else
            echo "❌ Neither production nor development file found for $file"
            exit 1
        fi
    fi
done

# Wait for ArgoCD server to be ready
echo "⏳ Waiting for ArgoCD server to be ready (this may take several minutes)..."
kubectl wait --for=condition=Available --timeout=600s deployment/argocd-server -n argocd

# Get ArgoCD admin password (production should use external secret management)
echo "🔑 Retrieving ArgoCD admin password..."
ADMIN_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null || echo "CHECK_SECRET_MANAGER")

# Display access information
echo ""
echo "🎉 ArgoCD PRODUCTION deployment completed successfully!"
echo ""
echo "📋 Production Access Information:"
echo "   URL: https://argocd.smartcity.local"
echo "   Username: admin"
if [ "$ADMIN_PASSWORD" = "CHECK_SECRET_MANAGER" ]; then
    echo "   Password: *** CHECK YOUR SECRET MANAGEMENT SYSTEM ***"
else
    echo "   Password: $ADMIN_PASSWORD"
fi
echo ""
echo "🌐 GRPC Access (for ArgoCD CLI):"
echo "   Server: argocd-grpc.smartcity.local:443"
echo ""
echo "🔐 Production Security Reminders:"
echo "   ✅ Verify TLS certificates are properly configured"
echo "   ✅ Change default admin password immediately"
echo "   ✅ Configure proper RBAC policies"
echo "   ✅ Set up backup procedures"
echo "   ✅ Enable audit logging"
echo "   ✅ Configure monitoring and alerting"
echo "   ✅ Review and apply network policies"
echo ""
echo "📝 Next Steps:"
echo "   1. Verify DNS entries point to correct load balancer"
echo "   2. Test external access and SSL certificates"
echo "   3. Configure identity provider (OIDC/SAML)"
echo "   4. Set up application repositories"
echo "   5. Configure GitOps workflows"
echo ""
echo "🔍 Monitor production deployment:"
echo "   kubectl get pods -n argocd -o wide"
echo "   kubectl get svc -n argocd"
echo "   kubectl get ingress -n argocd"
echo "   kubectl logs -f deployment/argocd-server -n argocd"
echo ""

# Check production deployment status
echo "📊 Production ArgoCD Status:"
kubectl get pods -n argocd -o wide

echo ""
echo "🛡️ Security Status:"
# Check for insecure configurations
INSECURE_FLAGS=$(kubectl get deployment argocd-server -n argocd -o jsonpath='{.spec.template.spec.containers[0].args}' | grep -o '\--insecure' | wc -l)
if [ "$INSECURE_FLAGS" -gt 0 ]; then
    echo "   ⚠️ WARNING: ArgoCD server is running with --insecure flag"
    echo "   This should be disabled in production"
else
    echo "   ✅ ArgoCD server is running in secure mode"
fi

echo ""
echo "✅ ArgoCD PRODUCTION deployment script completed!"
echo ""
echo "🚨 IMPORTANT: Complete the production security checklist before going live!"
