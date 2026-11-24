#!/usr/bin/env bash
set -uo pipefail
echo "[cleanup] Question 3 - cri-dockerd"
systemctl disable --now cri-docker.service cri-docker.socket >/dev/null 2>&1
dpkg -r cri-dockerd >/dev/null 2>&1
rm -f /etc/sysctl.d/99-k8s.conf "$HOME/cri-dockerd_0.3.6.3-0.ubuntu-jammy_amd64.deb"
echo "[cleanup] done"
