#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAG="${TAG:-$(date +%Y%m%d-%H%M%S)}"
IMAGE="aks-spring-demo:${TAG}"
IMAGE_TAR="${IMAGE_TAR:-/tmp/aks-spring-demo.tar}"
LOADER_POD="${LOADER_POD:-image-loader}"

if ! kubectl cluster-info &>/dev/null; then
  echo "ERROR: No Kubernetes cluster is reachable."
  echo ""
  echo "Enable Kubernetes in Docker Desktop (Settings → Kubernetes), or run:"
  echo "  minikube start"
  echo ""
  echo "Then verify: kubectl get nodes"
  exit 1
fi

echo "Installing NGINX Ingress Controller (if needed)..."
"${ROOT}/scripts/install-ingress-nginx.sh"

if [[ "${ENABLE_INGRESS_TLS:-true}" == "true" ]]; then
  echo "Creating local TLS Secret for host demo.local..."
  HOST=demo.local "${ROOT}/scripts/generate-tls-secret.sh"
fi

NODE_NAME="$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')"

echo "Building image: ${IMAGE}"
docker build -t "${IMAGE}" "${ROOT}"

kubectl apply -f "${ROOT}/k8s/base/namespace.yaml"

# Docker Desktop Kubernetes uses containerd and cannot see images from 'docker build'.
# Import the image directly into the node's containerd store.
echo "Loading image into cluster node: ${NODE_NAME}"
docker save "${IMAGE}" -o "${IMAGE_TAR}"

kubectl delete pod "${LOADER_POD}" -n aks-demo --ignore-not-found --wait=true 2>/dev/null || true
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${LOADER_POD}
  namespace: aks-demo
spec:
  nodeName: ${NODE_NAME}
  restartPolicy: Never
  hostPID: true
  hostNetwork: true
  containers:
    - name: loader
      image: alpine:3.19
      command: ["sleep", "300"]
      securityContext:
        privileged: true
      volumeMounts:
        - name: host
          mountPath: /host
  volumes:
    - name: host
      hostPath:
        path: /
        type: Directory
EOF

kubectl wait --for=condition=Ready "pod/${LOADER_POD}" -n aks-demo --timeout=60s
kubectl cp "${IMAGE_TAR}" "aks-demo/${LOADER_POD}:/host/tmp/aks-spring-demo.tar"
kubectl exec -n aks-demo "${LOADER_POD}" -- chroot /host ctr -n k8s.io images import /tmp/aks-spring-demo.tar
kubectl delete pod "${LOADER_POD}" -n aks-demo --wait=false

echo "Stamping local overlay with image tag: ${TAG}"
KUSTOMIZATION="${ROOT}/k8s/overlays/local/kustomization.yaml"
tmp=$(mktemp)
sed "s/newTag: .*/newTag: \"${TAG}\"/" "${KUSTOMIZATION}" > "${tmp}" && mv "${tmp}" "${KUSTOMIZATION}"

echo "Applying Kubernetes manifests (local overlay)..."
kubectl apply -k "${ROOT}/k8s/overlays/local"

echo "Waiting for deployment..."
kubectl rollout status deployment/aks-spring-demo -n aks-demo --timeout=180s

INGRESS_IP="$("${ROOT}/scripts/ingress-address.sh" || true)"
echo ""
echo "Demo deployed — image: ${IMAGE}"
echo "  kubectl get ingress -n aks-demo"
echo "  kubectl get svc -n ingress-nginx ingress-nginx-controller"
echo ""
if [[ -n "${INGRESS_IP}" ]]; then
  echo "Ingress LoadBalancer address: ${INGRESS_IP}"
  echo "  curl http://${INGRESS_IP}/api/hello"
else
  echo "LoadBalancer IP not ready yet (common on Docker Desktop). Use port-forward:"
  echo "  kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80 8443:443"
  echo "  curl http://localhost:8080/api/hello"
fi
echo ""
echo "TLS + host routing (local overlay uses demo.local):"
echo "  echo '127.0.0.1 demo.local' | sudo tee -a /etc/hosts"
echo "  curl -k https://demo.local:8443/api/hello   # with port-forward on 8443"
