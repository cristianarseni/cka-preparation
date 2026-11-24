#!/usr/bin/env bash
set -uo pipefail
echo "[cleanup] Question 7 - StorageClass"
kubectl delete namespace sc-workload --ignore-not-found --wait=false
kubectl delete storageclass legacy-standard local-path --ignore-not-found

# Put back the playground's own 'local-path' StorageClass, if setup saved one.
ORIG="${HOME}/.cka-prep-state/07-local-path-original.json"
if [ -s "$ORIG" ]; then
  if kubectl create -f "$ORIG" >/dev/null 2>&1; then
    echo "[cleanup] restored the playground's original 'local-path' StorageClass"
    rm -f "$ORIG"
  else
    echo "[cleanup] WARNING: could not restore 'local-path' - the saved copy is in $ORIG"
  fi
fi

rm -f "${HOME}/.cka-prep-state/07-storageclass.state"
echo "[cleanup] done"
