#!/bin/bash

# Deploy Individual Components for Smart City GitOps - Development Environment
# This script allows deploying individual components using Kustomize

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../" && pwd)"
INFRA_DIR="$PROJECT_ROOT/k8s/infra/dev"

# Function to display usage
usage() {
    echo "Usage: $0 [COMPONENT]"
    echo ""
    echo "Available components:"
    echo "  postgres    - Deploy PostgreSQL database"
    echo "  mongo       - Deploy MongoDB database"
    echo "  redis       - Deploy Redis cache"
    echo "  rabbitmq    - Deploy RabbitMQ message broker"
    echo "  keycloak    - Deploy Keycloak identity provider"
    echo "  argocd      - Deploy ArgoCD GitOps platform"
    echo "  all         - Deploy all infrastructure components"
    echo ""
    echo "Examples:"
    echo "  $0 postgres"
    echo "  $0 all"
    exit 1
}

# Check if component is provided
if [ $# -eq 0 ]; then
    echo "❌ Error: No component specified"
    usage
fi

COMPONENT=$1

echo "🚀 Starting component deployment for Smart City GitOps - DEV environment..."
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

# Function to deploy component
deploy_component() {
    local comp=$1
    local path=$2
    local wait_condition=$3
    local timeout=$4

    echo "🏗️ Deploying $comp using Kustomize..."
    kubectl apply -k "$path"

    if [ -n "$wait_condition" ]; then
        echo "⏳ Waiting for $comp to be ready..."
        eval "$wait_condition" || echo "⚠️ $comp may still be starting..."
    fi

    echo "✅ $comp deployment completed!"
}

# Deploy based on component
case $COMPONENT in
    postgres)
        deploy_component "PostgreSQL" "$INFRA_DIR/postgres" \
            "kubectl wait --for=condition=Ready --timeout=300s pod -l app=postgres -n smartcity" 300
        ;;
    mongo)
        deploy_component "MongoDB" "$INFRA_DIR/mongo" \
            "kubectl wait --for=condition=Ready --timeout=300s pod -l app=mongodb -n smartcity" 300
        ;;
    redis)
        deploy_component "Redis" "$INFRA_DIR/redis" \
            "kubectl wait --for=condition=Available --timeout=180s deployment/redis -n smartcity" 180
        ;;
    rabbitmq)
        deploy_component "RabbitMQ" "$INFRA_DIR/rabbitmq" \
            "kubectl wait --for=condition=Available --timeout=180s deployment/rabbitmq -n smartcity" 180
        ;;
    keycloak)
        deploy_component "Keycloak" "$INFRA_DIR/keycloack" \
            "kubectl wait --for=condition=Available --timeout=300s deployment/keycloak -n smartcity" 300
        ;;
    argocd)
        deploy_component "ArgoCD" "$INFRA_DIR/argocd" \
            "kubectl wait --for=condition=Available --timeout=300s deployment/argocd-server -n argocd" 300

        # Get ArgoCD admin password
        echo "🔑 Retrieving ArgoCD admin password..."
        ADMIN_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null || echo "admin123")
        echo "   ArgoCD URL: https://argocd.dev.smartcity.local"
        echo "   Username: admin"
        echo "   Password: $ADMIN_PASSWORD"
        ;;
    all)
        echo "🏗️ Deploying all infrastructure components using Kustomize..."
        kubectl apply -k "$INFRA_DIR"

        echo "⏳ Waiting for all components to be ready..."
        kubectl wait --for=condition=Ready --timeout=300s pod -l component=database -n smartcity || echo "⚠️ Some database pods may still be starting..."
        kubectl wait --for=condition=Ready --timeout=180s pod -l component=cache -n smartcity || echo "⚠️ Redis may still be starting..."
        kubectl wait --for=condition=Ready --timeout=180s pod -l component=messaging -n smartcity || echo "⚠️ RabbitMQ may still be starting..."
        kubectl wait --for=condition=Ready --timeout=300s pod -l app=keycloak -n smartcity || echo "⚠️ Keycloak may still be starting..."

        echo "✅ All infrastructure components deployed!"
        ;;
    *)
        echo "❌ Error: Unknown component '$COMPONENT'"
        usage
        ;;
esac

# Display final status
echo ""
echo "📊 Deployment Status:"
case $COMPONENT in
    argocd)
        kubectl get pods -n argocd
        ;;
    *)
        kubectl get pods -n smartcity
        ;;
esac

echo ""
echo "🎉 Component deployment completed!"
echo ""
echo "📝 Next Steps:"
echo "   - Monitor logs: kubectl logs -f [component-name] -n [namespace]"
echo "   - Check services: kubectl get svc -n [namespace]"
echo "   - Check PVCs: kubectl get pvc -n [namespace]"

echo "✅ Script completed successfully!"
