#!/usr/bin/env bash
# Creates Azure resources for the demo. Customize variables below.
set -euo pipefail

RESOURCE_GROUP="${RESOURCE_GROUP:-aks-demo-rg}"
LOCATION="${LOCATION:-eastus}"
ACR_NAME="${ACR_NAME:-aksdemodemo$(openssl rand -hex 3)}"
AKS_NAME="${AKS_NAME:-aks-demo-cluster}"
# Use 2-vCPU SKUs on free/low-quota subscriptions (4 vCPU regional limit in eastus is common).
NODE_COUNT="${NODE_COUNT:-1}"
NODE_VM_SIZE="${NODE_VM_SIZE:-standard_dc2as_v5}"

echo "Resource group: ${RESOURCE_GROUP}"
echo "Location:       ${LOCATION}"
echo "ACR name:       ${ACR_NAME}"
echo "AKS name:       ${AKS_NAME}"
echo "Node count:     ${NODE_COUNT}"
echo "Node VM size:   ${NODE_VM_SIZE}"

az group create --name "${RESOURCE_GROUP}" --location "${LOCATION}"

az acr create --resource-group "${RESOURCE_GROUP}" --name "${ACR_NAME}" --sku Basic --admin-enabled false

az aks create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${AKS_NAME}" \
  --node-count "${NODE_COUNT}" \
  --node-vm-size "${NODE_VM_SIZE}" \
  --attach-acr "${ACR_NAME}" \
  --generate-ssh-keys

az aks get-credentials --resource-group "${RESOURCE_GROUP}" --name "${AKS_NAME}"

echo ""
echo "Azure setup complete."
echo "  ACR login server: ${ACR_NAME}.azurecr.io"
echo ""
echo "Next steps:"
echo "  1. Build and push: ./scripts/push-to-acr.sh ${ACR_NAME}"
echo "  2. Update k8s/overlays/azure/kustomization.yaml with your ACR name"
echo "  3. Deploy: kubectl apply -k k8s/overlays/azure"
