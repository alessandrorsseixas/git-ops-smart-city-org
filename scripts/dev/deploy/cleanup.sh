#!/bin/bash

# Cleanup/Undeploy Smart City GitOps - Development Environment
# This script removes all deployed resources

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../" && pwd)"
INFRA_DIR="$PROJECT_ROOT/k8s/infra/dev"

echo "🧹 Smart City GitOps - Cleanup Script"
echo "   This will remove ALL deployed resources including data!"
echo ""

# Warning and confirmation
echo "⚠️  WARNING: This will delete:"
echo "   - All pods and deployments"
echo "   - All services and ingresses"
echo "   - All persistent volumes and data"
echo "   - All secrets and configmaps"
echo "   - Complete namespaces: smartcity, argocd"
echo ""
echo "💀 ALL DATA WILL BE LOST!"
echo ""

read -p "🤔 Are you sure you want to proceed? Type 'DELETE' to confirm: " -r
echo
if [[ $REPLY != "DELETE" ]]; then
    echo "❌ Cleanup cancelled - confirmation not received"
    exit 0
fi

echo "🔄 Starting cleanup process..."

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
echo ""

# Function to safely delete resources
safe_delete() {
    local resource_type=$1
    local resource_name=$2
    local namespace=$3
    
    if [ -n "$namespace" ]; then
        local ns_flag="-n $namespace"
        local context="in namespace $namespace"
    else
        local ns_flag=""
        local context="(cluster-wide)"
    fi
    
    if kubectl get $resource_type $resource_name $ns_flag &> /dev/null; then
        echo "   Deleting $resource_type/$resource_name $context..."
        kubectl delete $resource_type $resource_name $ns_flag --ignore-not-found=true --timeout=60s
    else
        echo "   $resource_type/$resource_name $context not found (already deleted)"
    fi
}

# 1. Delete ArgoCD resources
echo "🎯 Removing ArgoCD resources..."
if kubectl get namespace argocd &> /dev/null; then
    echo "   Deleting ArgoCD deployments..."
    kubectl delete deployment --all -n argocd --ignore-not-found=true --timeout=60s
    
    echo "   Deleting ArgoCD services..."
    kubectl delete service --all -n argocd --ignore-not-found=true
    
    echo "   Deleting ArgoCD ingresses..."
    kubectl delete ingress --all -n argocd --ignore-not-found=true
    
    echo "   Deleting ArgoCD configmaps and secrets..."
    kubectl delete configmap --all -n argocd --ignore-not-found=true
    kubectl delete secret --all -n argocd --ignore-not-found=true
    
    echo "   Deleting ArgoCD PVCs..."
    kubectl delete pvc --all -n argocd --ignore-not-found=true --timeout=60s
    
    echo "   Deleting ArgoCD RBAC..."
    kubectl delete clusterrole argocd-application-controller argocd-server --ignore-not-found=true
    kubectl delete clusterrolebinding argocd-application-controller argocd-server --ignore-not-found=true
    
    echo "   Deleting ArgoCD namespace..."
    kubectl delete namespace argocd --ignore-not-found=true --timeout=120s
else
    echo "   ArgoCD namespace not found (already deleted)"
fi

# 2. Delete SmartCity Infrastructure
echo "🏗️ Removing SmartCity Infrastructure..."
if kubectl get namespace smartcity &> /dev/null; then
    echo "   Deleting infrastructure deployments and statefulsets..."
    kubectl delete statefulset --all -n smartcity --ignore-not-found=true --timeout=60s
    kubectl delete deployment --all -n smartcity --ignore-not-found=true --timeout=60s
    
    echo "   Deleting services..."
    kubectl delete service --all -n smartcity --ignore-not-found=true
    
    echo "   Deleting configmaps and secrets..."
    kubectl delete configmap --all -n smartcity --ignore-not-found=true
    kubectl delete secret --all -n smartcity --ignore-not-found=true
    
    echo "   Deleting PVCs (this will delete all data!)..."
    kubectl delete pvc --all -n smartcity --ignore-not-found=true --timeout=120s
    
    echo "   Deleting SmartCity namespace..."
    kubectl delete namespace smartcity --ignore-not-found=true --timeout=120s
else
    echo "   SmartCity namespace not found (already deleted)"
fi

# 3. Clean up any remaining cluster-wide resources
echo "🧽 Cleaning up cluster-wide resources..."

# Clean up any orphaned PVs
echo "   Checking for orphaned persistent volumes..."
ORPHANED_PVS=$(kubectl get pv --no-headers 2>/dev/null | grep "Released\|Available" | awk '{print $1}' || true)
if [ -n "$ORPHANED_PVS" ]; then
    echo "   Found orphaned PVs, cleaning up..."
    for pv in $ORPHANED_PVS; do
        echo "     Deleting PV: $pv"
        kubectl delete pv "$pv" --ignore-not-found=true --timeout=60s
    done
else
    echo "   No orphaned PVs found"
fi

# Wait for resources to be fully deleted
echo "⏳ Waiting for resources to be fully deleted..."
sleep 10

# Final status check
echo ""
echo "📊 Cleanup Status Report:"
echo ""

# Check if namespaces still exist
echo "🔍 Checking namespaces:"
if kubectl get namespace smartcity &> /dev/null; then
    echo "   ⚠️ smartcity namespace still exists (may be terminating)"
    kubectl get namespace smartcity
else
    echo "   ✅ smartcity namespace deleted"
fi

if kubectl get namespace argocd &> /dev/null; then
    echo "   ⚠️ argocd namespace still exists (may be terminating)"
    kubectl get namespace argocd  
else
    echo "   ✅ argocd namespace deleted"
fi

# Check persistent volumes
echo ""
echo "🔍 Checking persistent volumes:"
PV_COUNT=$(kubectl get pv --no-headers 2>/dev/null | wc -l || echo "0")
if [ "$PV_COUNT" -eq 0 ]; then
    echo "   ✅ No persistent volumes remaining"
else
    echo "   📋 Remaining persistent volumes:"
    kubectl get pv
fi

# Check for any remaining smart city related resources
echo ""
echo "🔍 Checking for remaining smart city resources:"
REMAINING_RESOURCES=$(kubectl get all --all-namespaces 2>/dev/null | grep -E "(smartcity|argocd|postgres|redis|rabbitmq|keycloak)" || true)
if [ -z "$REMAINING_RESOURCES" ]; then
    echo "   ✅ No remaining smart city resources found"
else
    echo "   ⚠️ Some resources may still be terminating:"
    echo "$REMAINING_RESOURCES"
fi

echo ""
echo "🎉 Cleanup completed!"
echo ""
echo "📋 Summary:"
echo "   ✅ ArgoCD completely removed"
echo "   ✅ SmartCity infrastructure completely removed" 
echo "   ✅ All persistent data deleted"
echo "   ✅ Namespaces deleted"
echo "   ✅ Cluster-wide resources cleaned up"
echo ""
echo "📝 Next Steps:"
echo "   - Cluster is clean and ready for fresh deployment"
echo "   - Run ./deploy-all.sh to redeploy everything"
echo "   - Or run individual scripts: ./deploy-pvcs.sh, ./deploy-infra.sh, ./deploy-argocd.sh"
echo ""
echo "⚠️ Note: If resources are still terminating, wait a few minutes and check:"
echo "   kubectl get pods --all-namespaces"
echo "   kubectl get pv"
echo ""

echo "✅ Cleanup script completed!"
