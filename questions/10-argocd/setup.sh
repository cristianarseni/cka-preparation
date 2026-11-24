#!/usr/bin/env bash
# Question 10 - Argo CD : prepare the cluster
set -uo pipefail
echo "[setup] Question 10 - Argo CD"

# --- helm ---------------------------------------------------------------------
if ! command -v helm >/dev/null 2>&1; then
  echo "[setup] installing helm..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash >/dev/null 2>&1 \
    || { echo "[setup] ERROR: could not install helm. Install it manually, then run this again."; exit 1; }
fi
echo "[setup] helm $(helm version --short 2>/dev/null)"

# --- reset anything from a previous attempt -----------------------------------
helm uninstall argocd -n argocd >/dev/null 2>&1
helm repo remove argo >/dev/null 2>&1
mkdir -p /home/candidate 2>/dev/null || true
rm -f /home/candidate/argo-helm.yaml

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f - >/dev/null

# --- "The Argo CD CRDs have already been preinstalled in the cluster." ---------
if kubectl get crd applications.argoproj.io >/dev/null 2>&1; then
  echo "[setup] Argo CD CRDs are already installed"
else
  echo "[setup] preinstalling the Argo CD CRDs..."
  OK=no
  for V in v2.13.3 v2.12.6 v2.11.7; do
    BASE="https://raw.githubusercontent.com/argoproj/argo-cd/${V}/manifests/crds"
    if kubectl apply \
         -f "$BASE/application-crd.yaml" \
         -f "$BASE/appproject-crd.yaml" \
         -f "$BASE/applicationset-crd.yaml" >/dev/null 2>&1; then
      echo "[setup] applied Argo CD $V CRDs"; OK=yes; break
    fi
  done
  [ "$OK" = no ] && { echo "[setup] ERROR: could not download the Argo CD CRDs (no internet?)"; exit 1; }
fi

echo
kubectl get crd | grep argoproj.io || true
echo
echo "[setup] the template goes in /home/candidate/argo-helm.yaml"
echo "[setup] ready"
