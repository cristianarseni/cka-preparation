#!/usr/bin/env bash
set -uo pipefail
echo "[cleanup] Question 15 - CRDs"
rm -f /home/candidate/resources.yaml /home/candidate/subject.yaml
echo "[cleanup] answer files removed (the cert-manager CRDs were left installed)"
echo "[cleanup] to remove those too:  kubectl delete crd \$(kubectl get crd -o name | grep cert-manager.io | paste -sd' ')"
