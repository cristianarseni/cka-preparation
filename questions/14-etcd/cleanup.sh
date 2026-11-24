#!/usr/bin/env bash
set -uo pipefail
echo "[cleanup] Question 14 - etcd"
echo "  Nothing to remove - the task IS the repair."
echo "  If you are stuck, the originals are in /etc/kubernetes/manifests.cka-backup/"
echo "  Restore with:"
echo "    sudo cp /etc/kubernetes/manifests.cka-backup/*.yaml /etc/kubernetes/manifests/"
