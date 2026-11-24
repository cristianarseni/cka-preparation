#!/usr/bin/env bash
set -uo pipefail
echo "[cleanup] Question 10 - Argo CD"
helm uninstall argocd -n argocd >/dev/null 2>&1
helm repo remove argo >/dev/null 2>&1
kubectl delete namespace argocd --ignore-not-found --wait=false
rm -f /home/candidate/argo-helm.yaml
echo "[cleanup] done (the Argo CD CRDs were left in place)"
