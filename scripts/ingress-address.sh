#!/usr/bin/env bash
set -euo pipefail

# Prints the ingress LoadBalancer address (IP or hostname) when available.
kubectl get svc ingress-nginx-controller -n ingress-nginx \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}{.status.loadBalancer.ingress[0].hostname}{"\n"}'
