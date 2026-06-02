#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${IMAGE:-aks-spring-demo:1.0.0}"
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

echo "Applying Kubernetes manifests (local overlay)..."
kubectl apply -k "${ROOT}/k8s/overlays/local"

echo "Waiting for deployment..."
kubectl rollout status deployment/aks-spring-demo -n aks-demo --timeout=180s

echo ""
echo "Demo deployed. Get the external IP:"
echo "  kubectl get svc aks-spring-demo -n aks-demo"
echo ""
echo "Then call:"
echo "  curl http://<EXTERNAL-IP>/api/hello"
