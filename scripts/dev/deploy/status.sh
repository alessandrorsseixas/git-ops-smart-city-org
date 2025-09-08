#!/bin/bash

# Status monitoring for Smart City GitOps - Development Environment
# This script provides comprehensive status information about all deployments

set -e

echo "📊 Smart City GitOps - Status Dashboard"
echo "======================================"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check cluster connectivity
echo "🔍 Kubernetes Cluster Information:"
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster"
    echo "Please check your kubectl configuration and cluster status"
    exit 1
fi

# Get cluster info
kubectl cluster-info | head -3
echo ""

# Function to check namespace status
check_namespace() {
    local ns=$1
    local display_name=$2
    
    echo "📦 $display_name Namespace Status:"
    if kubectl get namespace "$ns" &> /dev/null; then
        echo "   ✅ Namespace '$ns' exists"
        
        # Get pods status
        local total_pods=$(kubectl get pods -n "$ns" --no-headers 2>/dev/null | wc -l)
        local running_pods=$(kubectl get pods -n "$ns" --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
        local pending_pods=$(kubectl get pods -n "$ns" --field-selector=status.phase=Pending --no-headers 2>/dev/null | wc -l)
        local failed_pods=$(kubectl get pods -n "$ns" --field-selector=status.phase=Failed --no-headers 2>/dev/null | wc -l)
        
        echo "   📋 Pods: $running_pods/$total_pods running, $pending_pods pending, $failed_pods failed"
        
        if [ "$total_pods" -gt 0 ]; then
            echo ""
            kubectl get pods -n "$ns" -o wide
            echo ""
        fi
        
        # Get services
        local svc_count=$(kubectl get svc -n "$ns" --no-headers 2>/dev/null | wc -l)
        if [ "$svc_count" -gt 0 ]; then
            echo "   🌐 Services ($svc_count):"
            kubectl get svc -n "$ns"
            echo ""
        fi
        
        # Get PVCs
        local pvc_count=$(kubectl get pvc -n "$ns" --no-headers 2>/dev/null | wc -l)
        if [ "$pvc_count" -gt 0 ]; then
            echo "   💾 Persistent Volume Claims ($pvc_count):"
            kubectl get pvc -n "$ns"
            echo ""
        fi
        
        # Get ingresses
        local ing_count=$(kubectl get ingress -n "$ns" --no-headers 2>/dev/null | wc -l)
        if [ "$ing_count" -gt 0 ]; then
            echo "   🔗 Ingresses ($ing_count):"
            kubectl get ingress -n "$ns"
            echo ""
        fi
        
    else
        echo "   ❌ Namespace '$ns' does not exist"
        echo ""
    fi
}

# Check SmartCity Infrastructure
check_namespace "smartcity" "SmartCity Infrastructure"

# Check ArgoCD
check_namespace "argocd" "ArgoCD GitOps"

# Overall cluster resources
echo "🌐 Cluster-wide Resources:"
echo ""

# Check nodes
echo "   🖥️  Nodes:"
kubectl get nodes -o wide
echo ""

# Check storage classes
echo "   💾 Storage Classes:"
kubectl get storageclass
echo ""

# Check persistent volumes
echo "   📦 Persistent Volumes:"
PV_COUNT=$(kubectl get pv --no-headers 2>/dev/null | wc -l)
if [ "$PV_COUNT" -gt 0 ]; then
    kubectl get pv -o wide
else
    echo "   No persistent volumes found"
fi
echo ""

# Resource usage summary
echo "📈 Resource Usage Summary:"
echo ""

# Calculate total resources requested
echo "   💻 CPU/Memory Requests by Namespace:"
for ns in smartcity argocd; do
    if kubectl get namespace "$ns" &> /dev/null; then
        local cpu_req=$(kubectl top pods -n "$ns" --no-headers 2>/dev/null | awk '{sum += $2} END {print sum}' || echo "N/A")
        local mem_req=$(kubectl top pods -n "$ns" --no-headers 2>/dev/null | awk '{sum += $3} END {print sum}' || echo "N/A") 
        echo "     $ns: CPU: ${cpu_req}m, Memory: ${mem_req}Mi"
    fi
done
echo ""

# Storage usage
echo "   💾 Storage Usage:"
TOTAL_STORAGE=$(kubectl get pvc --all-namespaces --no-headers 2>/dev/null | awk '{sum += $4} END {print sum}' || echo "0")
echo "     Total PVC Storage: ${TOTAL_STORAGE} (requested)"
echo ""

# Health check summary
echo "🏥 Health Check Summary:"
echo ""

# Check if key services are running
check_service_health() {
    local ns=$1
    local deployment=$2
    local display_name=$3
    
    if kubectl get deployment "$deployment" -n "$ns" &> /dev/null; then
        local ready_replicas=$(kubectl get deployment "$deployment" -n "$ns" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        local desired_replicas=$(kubectl get deployment "$deployment" -n "$ns" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
        
        if [ "$ready_replicas" = "$desired_replicas" ] && [ "$ready_replicas" != "0" ]; then
            echo "   ✅ $display_name: $ready_replicas/$desired_replicas replicas ready"
        else
            echo "   ⚠️ $display_name: $ready_replicas/$desired_replicas replicas ready"
        fi
    else
        echo "   ❌ $display_name: not deployed"
    fi
}

# Check key deployments
check_service_health "smartcity" "postgres" "PostgreSQL"
check_service_health "smartcity" "redis" "Redis"
check_service_health "smartcity" "rabbitmq" "RabbitMQ"
check_service_health "smartcity" "keycloak" "Keycloak"
check_service_health "argocd" "argocd-server" "ArgoCD Server"
check_service_health "argocd" "argocd-repo-server" "ArgoCD Repo Server"
check_service_health "argocd" "argocd-application-controller" "ArgoCD Application Controller"

echo ""

# Access information
echo "🌐 Access Information:"
echo ""

if kubectl get namespace smartcity &> /dev/null; then
    echo "   📍 SmartCity Infrastructure:"
    echo "     PostgreSQL: postgres-service.smartcity.svc.cluster.local:5432"
    echo "     Redis: redis-service.smartcity.svc.cluster.local:6379"
    echo "     RabbitMQ: rabbitmq-service.smartcity.svc.cluster.local:5672"
    echo "     RabbitMQ Management: http://rabbitmq-service.smartcity.svc.cluster.local:15672"
    echo "     Keycloak: http://keycloak-service.smartcity.svc.cluster.local:8080"
    echo ""
fi

if kubectl get namespace argocd &> /dev/null; then
    echo "   🎯 ArgoCD GitOps:"
    echo "     UI: https://argocd.dev.smartcity.local"
    echo "     GRPC: argocd-grpc.dev.smartcity.local:443"
    echo "     Username: admin"
    echo "     Password: admin123 (default)"
    echo ""
fi

# Quick troubleshooting
echo "🔧 Quick Troubleshooting:"
echo ""

# Check for pods not running
NOT_RUNNING=$(kubectl get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded --no-headers 2>/dev/null | wc -l)
if [ "$NOT_RUNNING" -gt 0 ]; then
    echo "   ⚠️ $NOT_RUNNING pod(s) not running:"
    kubectl get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded
    echo ""
    echo "   🔍 Check logs with: kubectl logs <pod-name> -n <namespace>"
else
    echo "   ✅ All pods are running successfully"
fi

# Check for pending PVCs
PENDING_PVCS=$(kubectl get pvc --all-namespaces --no-headers 2>/dev/null | grep "Pending" | wc -l)
if [ "$PENDING_PVCS" -gt 0 ]; then
    echo "   ⚠️ $PENDING_PVCS PVC(s) pending:"
    kubectl get pvc --all-namespaces | grep "Pending"
    echo "   💡 Check storage provisioner and available disk space"
else
    echo "   ✅ All PVCs are bound"
fi

echo ""

# Useful commands
echo "📚 Useful Commands:"
echo "   Monitor all pods: watch kubectl get pods --all-namespaces"
echo "   Check logs: kubectl logs -f <pod-name> -n <namespace>"
echo "   Port forward ArgoCD: kubectl port-forward svc/argocd-server 8080:80 -n argocd"
echo "   Port forward Keycloak: kubectl port-forward svc/keycloak-service 8080:8080 -n smartcity"
echo "   Get events: kubectl get events --all-namespaces --sort-by='.lastTimestamp'"
echo "   Resource usage: kubectl top pods --all-namespaces"
echo ""

# Final status
TOTAL_PODS_NOT_READY=$(kubectl get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded --no-headers 2>/dev/null | wc -l)
if [ "$TOTAL_PODS_NOT_READY" -eq 0 ] && [ "$PENDING_PVCS" -eq 0 ]; then
    echo "🎉 Overall Status: ✅ HEALTHY - All systems operational!"
else
    echo "⚠️ Overall Status: ATTENTION NEEDED - Check issues above"
fi

echo ""
echo "✅ Status check completed!"
