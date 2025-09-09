#!/bin/bash

# Kustomize Examples for Smart City GitOps
# This script demonstrates various Kustomize commands for the Smart City infrastructure

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../" && pwd)"
INFRA_DIR="$PROJECT_ROOT/k8s/infra/dev"

echo "🔧 Kustomize Examples for Smart City GitOps"
echo "📁 Infrastructure directory: $INFRA_DIR"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

echo "📋 Available Kustomize commands:"
echo ""

echo "1. 🔍 Preview what will be deployed (dry-run):"
echo "   kubectl kustomize $INFRA_DIR"
echo ""

echo "2. 🚀 Deploy entire infrastructure:"
echo "   kubectl apply -k $INFRA_DIR"
echo ""

echo "3. 🔧 Deploy individual components:"
echo "   kubectl apply -k $INFRA_DIR/postgres"
echo "   kubectl apply -k $INFRA_DIR/mongo"
echo "   kubectl apply -k $INFRA_DIR/redis"
echo "   kubectl apply -k $INFRA_DIR/rabbitmq"
echo "   kubectl apply -k $INFRA_DIR/keycloack"
echo "   kubectl apply -k $INFRA_DIR/argocd"
echo ""

echo "4. 📊 Check what resources will be created:"
echo "   kubectl kustomize $INFRA_DIR | grep 'kind:' | sort | uniq -c"
echo ""

echo "5. 🧹 Remove all resources:"
echo "   kubectl delete -k $INFRA_DIR"
echo ""

echo "6. 📝 View Kustomize configuration:"
echo "   cat $INFRA_DIR/kustomization.yaml"
echo ""

echo "7. 🔄 Update images for all components:"
echo "   kubectl set image -k $INFRA_DIR postgres=postgres:16-alpine"
echo ""

echo "8. 📊 Get deployment status:"
echo "   kubectl get pods -n smartcity"
echo "   kubectl get pods -n argocd"
echo ""

echo "9. 🔧 Edit component configurations:"
echo "   kubectl edit -k $INFRA_DIR/postgres"
echo ""

echo "10. 📋 List all managed resources:"
echo "    kubectl api-resources --namespaced=true | grep -E '(deployment|statefulset|service|configmap|secret|pvc)'"
echo ""

echo "🎯 Quick Commands:"
echo ""
echo "# Deploy and watch"
echo "kubectl apply -k $INFRA_DIR && watch kubectl get pods --all-namespaces"
echo ""
echo "# Check PVC status"
echo "kubectl get pvc --all-namespaces -o wide"
echo ""
echo "# View logs"
echo "kubectl logs -f deployment/redis -n smartcity"
echo "kubectl logs -f statefulset/postgres -n smartcity"
echo ""

echo "📚 Kustomize Documentation:"
echo "   https://kubectl.docs.kubernetes.io/references/kustomize/"
echo ""

echo "✅ Examples displayed successfully!"
echo ""
echo "💡 Tip: Use 'kubectl kustomize <dir> | less' to view generated manifests"
echo "💡 Tip: Use '--dry-run=client' to test changes before applying"
