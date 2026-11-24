#!/usr/bin/env bash
set -uo pipefail
echo "[cleanup] Question 3 - cri-dockerd"
systemctl disable --now cri-docker.service cri-docker.socket >/dev/null 2>&1
dpkg -r cri-dockerd >/dev/null 2>&1
rm -f /etc/sysctl.d/99-k8s.conf "$HOME/cri-dockerd_0.3.6.3-0.ubuntu-jammy_amd64.deb"

# Setup switched these OFF on the live node. Kubernetes networking needs them ON,
# so put them back even if the question was never solved.
sysctl -w net.ipv4.ip_forward=1                  >/dev/null 2>&1 || true
sysctl -w net.bridge.bridge-nf-call-iptables=1   >/dev/null 2>&1 || true
sysctl -w net.ipv6.conf.all.forwarding=1         >/dev/null 2>&1 || true
sysctl -w net.netfilter.nf_conntrack_max=131072  >/dev/null 2>&1 || true
echo "[cleanup] node networking sysctls restored"
echo "[cleanup] done"
