#!/usr/bin/env bash
# Question 15 - CRDs : prepare the cluster
set -uo pipefail
echo "[setup] Question 15 - CRDs (cert-manager)"

# The exam uses /home/candidate - use the same path so the muscle memory matches.
mkdir -p /home/candidate 2>/dev/null || true
rm -f /home/candidate/resources.yaml /home/candidate/subject.yaml

if kubectl get crd certificates.cert-manager.io >/dev/null 2>&1; then
  echo "[setup] cert-manager CRDs are already installed"
else
  echo "[setup] installing the cert-manager CRDs..."
  OK=no
  for V in v1.17.1 v1.16.2 v1.15.3 v1.14.5; do
    URL="https://github.com/cert-manager/cert-manager/releases/download/${V}/cert-manager.crds.yaml"
    if kubectl apply -f "$URL" >/dev/null 2>&1; then
      echo "[setup] applied cert-manager $V CRDs"; OK=yes; break
    fi
  done
  if [ "$OK" = no ]; then
    echo "[setup] ERROR: could not download the cert-manager CRDs."
    echo "[setup] Check the cluster has internet access, then run this again."
    exit 1
  fi
fi

echo
echo "[setup] cert-manager CRDs now in the cluster:"
kubectl get crd | grep cert-manager.io || true
echo
echo "[setup] answers go in /home/candidate/"
echo "[setup] ready"
