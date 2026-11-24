#!/usr/bin/env bash
set -uo pipefail
echo "[cleanup] Question 11 - PVC MariaDB"
kubectl delete namespace mariadb --ignore-not-found --wait=false
kubectl delete pv mariadb-pv --ignore-not-found --wait=false
rm -f "$HOME/mariadb-deployment.yaml" "${HOME}/.cka-prep-state/11-pvc-mariadb.state"
echo "[cleanup] done"
