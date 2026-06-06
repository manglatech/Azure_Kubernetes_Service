#!/usr/bin/env bash
set -euo pipefail

ACR_NAME="${1:?Usage: push-to-acr.sh <acr-name> [tag]}"
TAG="${2:-1.0.0}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${ACR_NAME}.azurecr.io/aks-spring-demo:${TAG}"

az acr login --name "${ACR_NAME}"
# AKS nodes are amd64; Mac builds arm64 by default — must cross-build for Azure.
docker build --platform linux/amd64 -t "${IMAGE}" "${ROOT}"
docker push "${IMAGE}"

echo "Pushed ${IMAGE}"
echo "Set newTag in k8s/overlays/azure/kustomization.yaml to: ${TAG}"
