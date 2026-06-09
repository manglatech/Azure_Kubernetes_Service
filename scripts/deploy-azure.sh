#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESOURCE_GROUP="${RESOURCE_GROUP:-aks-demo-rg}"
AKS_NAME="${AKS_NAME:-aks-demo-cluster}"

echo "Connecting to AKS cluster: ${AKS_NAME} (${RESOURCE_GROUP})"
az aks get-credentials --resource-group "${RESOURCE_GROUP}" --name "${AKS_NAME}" --overwrite-existing

echo "Checking user service is reachable in cluster..."
if ! kubectl get svc azure-user-service -n user-demo &>/dev/null; then
  echo "WARNING: azure-user-service not found in namespace user-demo."
  echo "Deploy it first:"
  echo "  cd ../Azure_User_Service && ./scripts/deploy-azure.sh"
  exit 1
fi

USER_READY="$(kubectl get deployment azure-user-service -n user-demo -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0)"
if [[ "${USER_READY}" -lt 1 ]]; then
  echo "WARNING: azure-user-service has no ready replicas. Deploy or wait for user-demo pods first."
  exit 1
fi

echo "Installing NGINX Ingress Controller (if needed)..."
AZURE_INGRESS_PATCH=true "${ROOT}/scripts/install-ingress-nginx.sh"

echo "Applying Kubernetes manifests (azure overlay)..."
kubectl apply -k "${ROOT}/k8s/overlays/azure"

echo "Waiting for deployment..."
kubectl rollout status deployment/aks-spring-demo -n aks-demo --timeout=180s

echo ""
echo "Waiting for Ingress LoadBalancer IP (up to 3 minutes)..."
for _ in $(seq 1 36); do
  INGRESS_IP="$("${ROOT}/scripts/ingress-address.sh" || true)"
  if [[ -n "${INGRESS_IP}" ]]; then
    break
  fi
  sleep 5
done

echo ""
echo "Demo app deployed behind NGINX Ingress."
echo "  kubectl get ingress -n aks-demo"
echo "  kubectl get svc -n ingress-nginx ingress-nginx-controller"
echo ""
if [[ -n "${INGRESS_IP}" ]]; then
  echo "Ingress LoadBalancer IP: ${INGRESS_IP}"
  echo "  curl http://${INGRESS_IP}/api/hello"
  echo "  curl http://${INGRESS_IP}/api/demo/users"
else
  echo "LoadBalancer IP not assigned yet. Watch:"
  echo "  kubectl get svc -n ingress-nginx ingress-nginx-controller -w"
fi
