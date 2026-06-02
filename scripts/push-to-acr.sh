#!/usr/bin/env bash
set -euo pipefail

ACR_NAME="${1:?Usage: push-to-acr.sh <acr-name> [tag]}"
TAG="${2:-1.0.0}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${ACR_NAME}.azurecr.io/aks-spring-demo:${TAG}"

az acr login --name "${ACR_NAME}"
docker build -t "${IMAGE}" "${ROOT}"
docker push "${IMAGE}"

echo "Pushed ${IMAGE}"
echo "Set newTag in k8s/overlays/azure/kustomization.yaml to: ${TAG}"
