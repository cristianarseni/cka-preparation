#!/usr/bin/env bash
# Question 14 - etcd : break the cluster on purpose
# DESTRUCTIVE - the API server will stop responding until the task is done.
set -uo pipefail
echo "[setup] Question 14 - etcd / control plane repair"
echo
echo "  ************************* WARNING *************************"
echo "  This BREAKS the control plane on purpose. kubectl will stop"
echo "  working until you fix it. Run this LAST in a session, or on"
echo "  a fresh playground of its own."
echo "  ***********************************************************"
echo

M=/etc/kubernetes/manifests
[ -d "$M" ] || { echo "[setup] ERROR: $M not found - run this on the control-plane node."; exit 1; }
[ "$(id -u)" -eq 0 ] || { echo "[setup] ERROR: must run as root."; exit 1; }

if [ -t 0 ]; then
  printf "  Type 'yes' to continue: "
  read -r ANSWER
  [ "$ANSWER" = "yes" ] || { echo "[setup] aborted"; exit 1; }
elif [ "${CKA_CONFIRM:-}" != "yes" ]; then
  echo "[setup] aborted - not running interactively."
  echo "[setup] to run it anyway:  CKA_CONFIRM=yes ./run.sh 14"
  exit 1
fi

BK=/etc/kubernetes/manifests.cka-backup
mkdir -p "$BK"
cp -n "$M/kube-apiserver.yaml" "$BK/kube-apiserver.yaml" 2>/dev/null || true
cp -n "$M/kube-scheduler.yaml" "$BK/kube-scheduler.yaml" 2>/dev/null || true
echo "[setup] originals backed up in $BK (for your own emergency use)"

# Fault 1: the apiserver points at etcd's PEER port (2380) instead of its
# CLIENT port (2379), so it can never establish a connection.
sed -i 's#\(--etcd-servers=[^ ]*:\)2379#\12380#' "$M/kube-apiserver.yaml"

# Fault 2: the scheduler asks for more CPU than the node has, so the kubelet
# refuses to admit the static Pod.
sed -i '/kube-scheduler/,$ s/^\([[:space:]]*\)cpu: .*/\1cpu: 8/' "$M/kube-scheduler.yaml"

echo "[setup] two faults introduced."
echo "[setup] give the kubelet ~60s, then start diagnosing."
echo
echo "[setup] ready - good luck"
