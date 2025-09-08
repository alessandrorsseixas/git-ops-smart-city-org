Deployment scripts for infra/dev

- deploy-infra-dev.sh: applies k8s/infra/dev kustomization
- deploy-pvcs-dev.sh: applies PVC manifests individually

Usage:
  ./deploy-infra-dev.sh --namespace smartcity
  ./deploy-pvcs-dev.sh --namespace smartcity
