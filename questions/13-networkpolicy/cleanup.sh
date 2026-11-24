#!/usr/bin/env bash
set -uo pipefail
echo "[cleanup] Question 13 - NetworkPolicy"
kubectl delete namespace frontend backend --ignore-not-found --wait=false
rm -rf "$HOME/netpol" "${HOME}/.cka-prep-state/13-networkpolicy.state"
echo "[cleanup] done"
