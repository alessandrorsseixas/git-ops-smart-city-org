#!/bin/bash

# RabbitMQ Deployment Script for Smart City
# This script deploys RabbitMQ with all necessary components

set -e

NAMESPACE="smartcity"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🐰 Starting RabbitMQ deployment for Smart City..."

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
    "rabbitmq-secret.yaml"
    "rabbitmq-configmap.yaml"
    "rabbitmq-pvc.yaml"
    "rabbitmq-backup-pvc.yaml"
    "rabbitmq-backup-configmap.yaml"
    "rabbitmq-deployment.yaml"
    "rabbitmq-networkpolicy.yaml"
    "rabbitmq-backup-cronjob.yaml"
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

# Wait for RabbitMQ to be ready
print_status "Waiting for RabbitMQ deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/rabbitmq -n "$NAMESPACE"

# Wait for pods to be ready
print_status "Waiting for RabbitMQ pods to be ready..."
kubectl wait --for=condition=ready pod -l app=rabbitmq -n "$NAMESPACE" --timeout=300s

# Verify deployment
print_status "Verifying RabbitMQ deployment..."

# Check if pods are running
if kubectl get pods -l app=rabbitmq -n "$NAMESPACE" | grep -q "Running"; then
    print_status "✅ RabbitMQ pods are running"
else
    print_error "❌ RabbitMQ pods are not running"
    kubectl get pods -l app=rabbitmq -n "$NAMESPACE"
    exit 1
fi

# Check if service exists
if kubectl get svc rabbitmq -n "$NAMESPACE" >/dev/null 2>&1; then
    print_status "✅ RabbitMQ service is available"
else
    print_error "❌ RabbitMQ service not found"
    exit 1
fi

# Test RabbitMQ connection
print_status "Testing RabbitMQ connection..."
kubectl run rabbitmq-test-connection --image=curlimages/curl:latest --rm -i --restart=Never \
    --namespace="$NAMESPACE" \
    --env="RABBITMQ_USER=smartcity" \
    --env="RABBITMQ_PASSWORD=smartcity123" \
    -- sh -c 'curl -s -u "$RABBITMQ_USER:$RABBITMQ_PASSWORD" http://rabbitmq.smartcity.svc.cluster.local:15672/api/overview | grep -q "rabbitmq_version" && echo "Connection successful" || echo "Connection failed"' || {
    print_error "❌ RabbitMQ connection test failed"
    exit 1
}

print_status "✅ RabbitMQ connection test successful"

# Display connection information
echo ""
echo "🐰 RabbitMQ deployment completed successfully!"
echo ""
echo "📋 Connection Information:"
echo "  AMQP URL: amqp://smartcity:smartcity123@rabbitmq.smartcity.svc.cluster.local:5672/"
echo "  Management UI: http://rabbitmq.smartcity.svc.cluster.local:15672/"
echo "  Prometheus Metrics: http://rabbitmq.smartcity.svc.cluster.local:15692/metrics"
echo ""
echo "👤 Users:"
echo "  smartcity / smartcity123 (administrator)"
echo "  admin / admin123 (administrator)"
echo ""
echo "📊 Pre-configured Resources:"
echo "  VHosts: /, smartcity"
echo "  Exchanges: smartcity.topic, smartcity.direct"
echo "  Queues: smartcity.notifications, smartcity.events"
echo ""
echo "🛠️  Available Commands:"
echo "  View logs: kubectl logs -l app=rabbitmq -n $NAMESPACE"
echo "  Scale deployment: kubectl scale deployment rabbitmq --replicas=2 -n $NAMESPACE"
echo "  Manual backup: kubectl create job manual-backup --from=cronjob/rabbitmq-backup -n $NAMESPACE"
echo "  Check status: kubectl get all -l app=rabbitmq -n $NAMESPACE"
echo "  Management UI: kubectl port-forward svc/rabbitmq 15672:15672 -n $NAMESPACE"
echo ""
echo "💾 Backup Information:"
echo "  Automatic backups run daily at 3:00 AM"
echo "  Backup location: rabbitmq-backup-pvc (/backup)"
echo "  Retention: 7 days"
echo ""
echo "🔒 Security:"
echo "  Network policies are in place"
echo "  Authentication is required"
echo "  Management interface protected"
