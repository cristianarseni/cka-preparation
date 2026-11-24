#!/usr/bin/env bash
set -uo pipefail
echo "[cleanup] Question 9 - PriorityClass"
kubectl delete namespace priority --ignore-not-found --wait=false
kubectl delete priorityclass low-priority medium-priority platform-critical high-priority --ignore-not-found
rm -f "${HOME}/.cka-prep-state/09-priorityclass.state"
echo "[cleanup] done"
