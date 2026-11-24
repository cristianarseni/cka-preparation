#!/usr/bin/env bash
set -uo pipefail
echo "[cleanup] Question 4 - Resource allocation"
kubectl delete namespace relative-fawn --ignore-not-found --wait=false
echo "[cleanup] done"
