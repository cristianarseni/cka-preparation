#!/usr/bin/env bash
set -uo pipefail
echo "[cleanup] Question 5 - Sidecar"
kubectl delete deploy synergy-leverager --ignore-not-found --wait=false
echo "[cleanup] done"
