#!/usr/bin/env bash
set -euo pipefail

# Official ingress-nginx static manifest (cloud provider — LoadBalancer Service).
INGRESS_NGINX_VERSION="${INGRESS_NGINX_VERSION:-1.11.3}"
INGRESS_MANIFEST="https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v${INGRESS_NGINX_VERSION}/deploy/static/provider/cloud/deploy.yaml"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AZURE_PATCH="${ROOT}/k8s/overlays/azure/ingress-nginx-patch.yaml"

if ! kubectl get namespace ingress-nginx &>/dev/null; then
  echo "Installing NGINX Ingress Controller (${INGRESS_NGINX_VERSION})..."
  kubectl apply -f "${INGRESS_MANIFEST}"
else
  echo "NGINX Ingress Controller namespace already exists — ensuring manifest is applied..."
  kubectl apply -f "${INGRESS_MANIFEST}"
fi

# Azure AKS: health probe must hit /healthz on the controller.
if [[ "${AZURE_INGRESS_PATCH:-}" == "true" ]] || \
   kubectl get nodes -o jsonpath='{.items[0].spec.providerID}' 2>/dev/null | grep -q Azure; then
  if [[ -f "${AZURE_PATCH}" ]]; then
    echo "Applying Azure Load Balancer health probe patch..."
    kubectl apply -f "${AZURE_PATCH}"
  fi
fi

echo "Waiting for ingress-nginx controller..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

echo ""
echo "NGINX Ingress Controller is ready."
echo "  kubectl get svc -n ingress-nginx ingress-nginx-controller"
echo ""
echo "External IP (LoadBalancer) may take 1–2 minutes on Azure:"
echo "  kubectl get svc -n ingress-nginx ingress-nginx-controller -w"
