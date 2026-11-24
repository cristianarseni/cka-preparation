#!/usr/bin/env bash
set -uo pipefail
echo "[cleanup] Question 2 - Ingress"
kubectl delete namespace sound-repeater --ignore-not-found --wait=false
sed -i '/[[:space:]]example\.org$/d' /etc/hosts 2>/dev/null
echo "[cleanup] done  (the ingress controller was left installed - other questions use it)"
echo "[cleanup] to remove it too:  kubectl delete ns ingress-nginx"
