#!/usr/bin/env bash
set -euo pipefail

# Creates a self-signed TLS Secret for local Ingress learning (demo.local).
HOST="${HOST:-demo.local}"
SECRET_NAME="${SECRET_NAME:-aks-spring-demo-tls}"
NAMESPACE="${NAMESPACE:-aks-demo}"
DAYS="${DAYS:-365}"
TMPDIR="${TMPDIR:-/tmp/aks-demo-tls}"

mkdir -p "${TMPDIR}"
KEY="${TMPDIR}/tls.key"
CRT="${TMPDIR}/tls.crt"

echo "Generating self-signed certificate for: ${HOST}"
openssl req -x509 -nodes -days "${DAYS}" -newkey rsa:2048 \
  -keyout "${KEY}" \
  -out "${CRT}" \
  -subj "/CN=${HOST}" \
  -addext "subjectAltName=DNS:${HOST},DNS:localhost,IP:127.0.0.1"

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

kubectl delete secret "${SECRET_NAME}" -n "${NAMESPACE}" --ignore-not-found
kubectl create secret tls "${SECRET_NAME}" \
  --cert="${CRT}" \
  --key="${KEY}" \
  -n "${NAMESPACE}"

echo ""
echo "TLS Secret created: ${NAMESPACE}/${SECRET_NAME}"
echo "Add to /etc/hosts:  127.0.0.1  ${HOST}"
echo ""
echo "Test (after port-forward on 443):"
echo "  curl -k https://${HOST}/api/hello"
