#!/bin/bash

# Redis Deployment Script for Smart City
# This script deploys Redis with all necessary components

set -e

NAMESPACE="smartcity"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔴 Starting Redis deployment for Smart City..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if namespace exists
if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
    print_status "Creating namespace: $NAMESPACE"
    kubectl create namespace "$NAMESPACE"
else
    print_status "Namespace $NAMESPACE already exists"
fi

# Apply manifests in order
MANIFESTS=(
    "redis-secret.yaml"
    "redis-configmap.yaml"
    "redis-pvc.yaml"
    "redis-backup-pvc.yaml"
    "redis-backup-configmap.yaml"
    "redis-deployment.yaml"
    "redis-networkpolicy.yaml"
    "redis-backup-cronjob.yaml"
)

for manifest in "${MANIFESTS[@]}"; do
    if [ -f "$SCRIPT_DIR/$manifest" ]; then
        print_status "Applying $manifest..."
        kubectl apply -f "$SCRIPT_DIR/$manifest"
    else
        print_error "Manifest file not found: $SCRIPT_DIR/$manifest"
        exit 1
    fi
done

# Wait for Redis to be ready
print_status "Waiting for Redis deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/redis -n "$NAMESPACE"

# Wait for pods to be ready
print_status "Waiting for Redis pods to be ready..."
kubectl wait --for=condition=ready pod -l app=redis -n "$NAMESPACE" --timeout=300s

# Verify deployment
print_status "Verifying Redis deployment..."

# Check if pods are running
if kubectl get pods -l app=redis -n "$NAMESPACE" | grep -q "Running"; then
    print_status "✅ Redis pods are running"
else
    print_error "❌ Redis pods are not running"
    kubectl get pods -l app=redis -n "$NAMESPACE"
    exit 1
fi

# Check if service exists
if kubectl get svc redis -n "$NAMESPACE" >/dev/null 2>&1; then
    print_status "✅ Redis service is available"
else
    print_error "❌ Redis service not found"
    exit 1
fi

# Test Redis connection
print_status "Testing Redis connection..."
kubectl run redis-test-connection --image=redis:7.2-alpine --rm -i --restart=Never \
    --namespace="$NAMESPACE" \
    --env="REDIS_PASSWORD=smartcity123" \
    -- redis-cli -h redis.smartcity.svc.cluster.local -a "$REDIS_PASSWORD" ping || {
    print_error "❌ Redis connection test failed"
    exit 1
}

print_status "✅ Redis connection test successful"

# Display connection information
echo ""
echo "🔴 Redis deployment completed successfully!"
echo ""
echo "📋 Connection Information:"
echo "  Host: redis.smartcity.svc.cluster.local"
echo "  Port: 6379"
echo "  Password: smartcity123"
echo ""
echo "🔗 Connection String:"
echo "  redis://:smartcity123@redis.smartcity.svc.cluster.local:6379"
echo ""
echo "🛠️  Available Commands:"
echo "  View logs: kubectl logs -l app=redis -n $NAMESPACE"
echo "  Scale deployment: kubectl scale deployment redis --replicas=2 -n $NAMESPACE"
echo "  Manual backup: kubectl create job manual-backup --from=cronjob/redis-backup -n $NAMESPACE"
echo "  Check status: kubectl get all -l app=redis -n $NAMESPACE"
echo "  Redis CLI: kubectl exec -it deployment/redis -n $NAMESPACE -- redis-cli"
echo ""
echo "💾 Backup Information:"
echo "  Automatic backups run daily at 4:00 AM"
echo "  Backup location: redis-backup-pvc (/backup)"
echo "  Retention: 7 days"
echo ""
echo "🔒 Security:"
echo "  Network policies are in place"
echo "  Authentication is required"
echo "  Dangerous commands are disabled/renamed"
