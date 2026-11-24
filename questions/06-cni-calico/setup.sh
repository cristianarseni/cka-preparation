#!/usr/bin/env bash
# Question 6 - CNI Calico : prepare the cluster
# DESTRUCTIVE - this removes the cluster's networking on purpose.
set -uo pipefail
echo "[setup] Question 6 - CNI Calico"
echo
echo "  ************************* WARNING *************************"
echo "  This removes the cluster's CNI. Pod networking will BREAK"
echo "  until you finish the task. Run this LAST in a session, or"
echo "  on a fresh playground of its own."
echo "  ***********************************************************"
echo

if [ -t 0 ]; then
  printf "  Type 'yes' to continue: "
  read -r ANSWER
  [ "$ANSWER" = "yes" ] || { echo "[setup] aborted"; exit 1; }
elif [ "${CKA_CONFIRM:-}" != "yes" ]; then
  echo "[setup] aborted - not running interactively."
  echo "[setup] to run it anyway:  CKA_CONFIRM=yes ./run.sh 6"
  exit 1
fi

echo "[setup] removing the existing CNI..."

# whichever one this playground shipped with
kubectl delete -n kube-flannel daemonset kube-flannel-ds --ignore-not-found >/dev/null 2>&1
kubectl delete namespace kube-flannel        --ignore-not-found --wait=false >/dev/null 2>&1
kubectl delete namespace calico-system       --ignore-not-found --wait=false >/dev/null 2>&1
kubectl delete namespace tigera-operator     --ignore-not-found --wait=false >/dev/null 2>&1
kubectl delete daemonset -n kube-system calico-node weave-net --ignore-not-found >/dev/null 2>&1
kubectl delete installation default --ignore-not-found >/dev/null 2>&1

# and the CNI config the kubelet reads
mkdir -p /etc/cni/net.d.cka-backup 2>/dev/null || true
mv /etc/cni/net.d/* /etc/cni/net.d.cka-backup/ 2>/dev/null || true

sleep 5
echo
echo "[setup] node status (expect NotReady - that is the point):"
kubectl get nodes 2>/dev/null || echo "  (api server not responding yet)"
echo
echo "[setup] ready - the cluster now has no CNI"
