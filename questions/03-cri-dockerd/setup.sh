#!/usr/bin/env bash
# Question 3 - cri-dockerd : prepare the host
set -uo pipefail
echo "[setup] Question 3 - cri-dockerd"

DEB_NAME=cri-dockerd_0.3.6.3-0.ubuntu-jammy_amd64.deb
DEB_URL="https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.6/${DEB_NAME}"

[ "$(id -u)" -eq 0 ] || echo "[setup] WARNING: not running as root - package and sysctl steps may fail"

# --- docker must be present for cri-dockerd to have anything to talk to -------
if command -v docker >/dev/null 2>&1; then
  echo "[setup] docker is present: $(docker --version 2>/dev/null)"
else
  echo
  echo "  ************************* WARNING *************************"
  echo "  docker is not installed, so setup has to install docker.io."
  echo "  On a Kubernetes node that can replace or clash with the"
  echo "  containerd the kubelet runs on. Run this LAST in a session,"
  echo "  or on a fresh playground of its own."
  echo "  ***********************************************************"
  echo
  if [ -t 0 ]; then
    printf "  Type 'yes' to continue: "
    read -r ANSWER
    [ "$ANSWER" = "yes" ] || { echo "[setup] aborted"; exit 1; }
  elif [ "${CKA_CONFIRM:-}" != "yes" ]; then
    echo "[setup] aborted - not running interactively."
    echo "[setup] to run it anyway:  CKA_CONFIRM=yes ./run.sh 3"
    exit 1
  fi
  echo "[setup] installing docker (the task says it is already installed)..."
  apt-get update -qq >/dev/null 2>&1
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq docker.io >/dev/null 2>&1 \
    && echo "[setup] docker installed" \
    || echo "[setup] WARNING: could not install docker - cri-docker may fail to start"
fi

# --- undo a previous attempt --------------------------------------------------
systemctl disable --now cri-docker.service cri-docker.socket >/dev/null 2>&1
dpkg -r cri-dockerd >/dev/null 2>&1
rm -f /etc/sysctl.d/99-k8s.conf /etc/sysctl.d/99-kubernetes.conf

# --- modules the sysctls depend on --------------------------------------------
modprobe br_netfilter 2>/dev/null || true
modprobe nf_conntrack 2>/dev/null || true

# --- put the sysctls into a known-wrong state ---------------------------------
sysctl -w net.bridge.bridge-nf-call-iptables=0 >/dev/null 2>&1 || true
sysctl -w net.ipv6.conf.all.forwarding=0        >/dev/null 2>&1 || true
sysctl -w net.ipv4.ip_forward=0                 >/dev/null 2>&1 || true
sysctl -w net.netfilter.nf_conntrack_max=65536  >/dev/null 2>&1 || true

# --- the package the task asks you to install ---------------------------------
if [ -f "$HOME/$DEB_NAME" ]; then
  echo "[setup] $DEB_NAME is already downloaded"
else
  echo "[setup] downloading $DEB_NAME ..."
  curl -fsSL -o "$HOME/$DEB_NAME" "$DEB_URL" \
    && echo "[setup] saved to $HOME/$DEB_NAME" \
    || { echo "[setup] ERROR: could not download the package (no internet?)"; exit 1; }
fi

echo
echo "[setup] starting values:"
for k in net.bridge.bridge-nf-call-iptables net.ipv6.conf.all.forwarding \
         net.ipv4.ip_forward net.netfilter.nf_conntrack_max; do
  printf '  %-40s %s\n' "$k" "$(sysctl -n $k 2>/dev/null || echo '<module not loaded>')"
done
echo "[setup] ready"
