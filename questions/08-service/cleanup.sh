#!/usr/bin/env bash
set -uo pipefail
echo "[cleanup] Question 8 - Service"
kubectl delete namespace spline-reticulator --ignore-not-found --wait=false
echo "[cleanup] done"
