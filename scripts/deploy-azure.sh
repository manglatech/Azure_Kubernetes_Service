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

echo "Applying Kubernetes manifests (azure overlay)..."
kubectl apply -k "${ROOT}/k8s/overlays/azure"

echo "Waiting for deployment..."
kubectl rollout status deployment/aks-spring-demo -n aks-demo --timeout=180s

echo ""
echo "Demo app deployed. Get the external IP:"
echo "  kubectl get svc aks-spring-demo -n aks-demo"
echo ""
echo "Then call:"
echo "  curl http://<EXTERNAL-IP>/api/hello"
echo "  curl http://<EXTERNAL-IP>/api/demo/users"
