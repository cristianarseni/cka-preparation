#!/usr/bin/env bash
set -uo pipefail
echo "[cleanup] Question 12 - Gateway API"
kubectl delete gateway web-gateway --ignore-not-found --wait=false
kubectl delete httproute web-route --ignore-not-found --wait=false
kubectl delete ingress web --ignore-not-found --wait=false
kubectl delete deploy web --ignore-not-found --wait=false
kubectl delete svc web --ignore-not-found --wait=false
kubectl delete secret web-tls --ignore-not-found
kubectl delete gatewayclass nginx --ignore-not-found
echo "[cleanup] done (the Gateway API CRDs were left installed)"
