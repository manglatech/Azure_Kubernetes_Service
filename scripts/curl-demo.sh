#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Normalize path — accept "api/hello" or "/api/hello"
RAW_PATH="${1:-/api/hello}"
PATH_SUFFIX="${RAW_PATH#/}"
PATH_SUFFIX="/${PATH_SUFFIX}"

CONTEXT="$(kubectl config current-context 2>/dev/null || echo unknown)"
INGRESS_IP="$("${ROOT}/scripts/ingress-address.sh" 2>/dev/null || true)"
NODEPORT="$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}' 2>/dev/null || true)"

try_curl() {
  local label="$1"
  local base_url="$2"
  local url="${base_url%/}${PATH_SUFFIX}"
  echo "Trying ${label} (${url})..."
  if curl -sf --connect-timeout 5 "${url}"; then
    echo ""
    return 0
  fi
  return 1
}

echo "kubectl context: ${CONTEXT}"
echo "Path: ${PATH_SUFFIX}"
echo ""

# 1. Ingress LoadBalancer IP (works on Azure; often fails on Docker Desktop Mac)
if [[ -n "${INGRESS_IP}" ]]; then
  echo "Ingress LoadBalancer IP: ${INGRESS_IP}"
  if try_curl "LoadBalancer IP" "http://${INGRESS_IP}"; then
    exit 0
  fi
  echo "  (not reachable from this machine — common on Docker Desktop)"
  echo ""
fi

# 2. NodePort on localhost
if [[ -n "${NODEPORT}" ]]; then
  if try_curl "NodePort :${NODEPORT}" "http://127.0.0.1:${NODEPORT}"; then
    exit 0
  fi
  if try_curl "NodePort :${NODEPORT}" "http://localhost:${NODEPORT}"; then
    exit 0
  fi
fi

# 3. Port-forward to ingress controller (most reliable on Docker Desktop)
echo "Starting temporary port-forward to ingress-nginx-controller:80 ..."
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 18080:80 >/tmp/curl-demo-pf.log 2>&1 &
PF_PID=$!
trap 'kill ${PF_PID:-} 2>/dev/null || true' EXIT
sleep 2

if try_curl "ingress port-forward :18080" "http://127.0.0.1:18080"; then
  exit 0
fi
if try_curl "ingress port-forward :18080" "http://localhost:18080"; then
  exit 0
fi

# 4. Direct port-forward to app Service (bypasses ingress — last resort)
echo "Ingress unreachable — trying direct port-forward to aks-spring-demo ..."
kill ${PF_PID} 2>/dev/null || true
kubectl port-forward -n aks-demo svc/aks-spring-demo 18081:80 >/tmp/curl-demo-app-pf.log 2>&1 &
APP_PF=$!
trap 'kill ${APP_PF:-} 2>/dev/null || true' EXIT
sleep 2

if try_curl "app port-forward :18081" "http://127.0.0.1:18081"; then
  echo "(reached app directly — ingress may need fixing)"
  exit 0
fi

echo "ERROR: Could not reach ${PATH_SUFFIX}."
echo ""
echo "Usage: $0 [/api/hello]   # leading slash optional"
echo ""
echo "Checks:"
echo "  kubectl get pods -n aks-demo"
echo "  kubectl get pods -n ingress-nginx"
echo "  kubectl get ingress -n aks-demo"
echo "  kubectl apply -k k8s/overlays/local   # re-apply ingress rules"
exit 1
