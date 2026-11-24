#!/usr/bin/env bash
set -uo pipefail
echo "[cleanup] Question 7 - StorageClass"
kubectl delete namespace sc-workload --ignore-not-found --wait=false
kubectl delete storageclass legacy-standard local-path --ignore-not-found
rm -f "${HOME}/.cka-prep-state/07-storageclass.state"
echo "[cleanup] done"
