#!/usr/bin/env bash
set -uo pipefail
echo "[cleanup] Question 16 - ConfigMap"
kubectl delete namespace nginx-static --ignore-not-found --wait=false
sed -i '/[[:space:]]web\.k8snginx\.local$/d' /etc/hosts 2>/dev/null
kubectl -n ingress-nginx scale deploy ingress-nginx-controller --replicas=1 >/dev/null 2>&1 || true
echo "[cleanup] done"
