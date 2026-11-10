#!/usr/bin/env bash
# Question 1 - HPA : remove everything this question created
set -uo pipefail
echo "[cleanup] Question 1 - HPA"
kubectl delete namespace autoscale --ignore-not-found --wait=false
echo "[cleanup] done"
