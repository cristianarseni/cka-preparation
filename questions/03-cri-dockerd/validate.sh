#!/usr/bin/env bash
# Question 3 - cri-dockerd : check the answer
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/common.sh"

echo "Checking Question 3 - cri-dockerd"
echo

# ------------------------------------------------------------------ package
if dpkg -s cri-dockerd >/dev/null 2>&1 && [ "$(dpkg -s cri-dockerd 2>/dev/null | sed -n 's/^Status: //p')" = "install ok installed" ]; then
  pass "the cri-dockerd package is installed  (version $(dpkg -s cri-dockerd 2>/dev/null | sed -n 's/^Version: //p'))"
else
  fail "the cri-dockerd package is installed  ${YELLOW}dpkg -i ~/cri-dockerd_0.3.6.3-0.ubuntu-jammy_amd64.deb${NC}"
fi

# ------------------------------------------------------------------ service
ENABLED=$(systemctl is-enabled cri-docker.service 2>/dev/null || echo "not-found")
if [ "$ENABLED" = "enabled" ]; then
  pass "cri-docker.service is enabled (starts on boot)"
else
  fail "cri-docker.service is enabled  ${YELLOW}got:${NC} $ENABLED"
fi

ACTIVE=$(systemctl is-active cri-docker.service 2>/dev/null || echo "inactive")
if [ "$ACTIVE" = "active" ]; then
  pass "cri-docker.service is active (running now)"
else
  fail "cri-docker.service is active  ${YELLOW}got:${NC} $ACTIVE"
  echo "         diagnose with:  systemctl status cri-docker  /  journalctl -u cri-docker -n 30"
fi

# ------------------------------------------------------------------ sysctls
echo
declare -A WANT=(
  [net.bridge.bridge-nf-call-iptables]=1
  [net.ipv6.conf.all.forwarding]=1
  [net.ipv4.ip_forward]=1
  [net.netfilter.nf_conntrack_max]=131072
)

for key in net.bridge.bridge-nf-call-iptables net.ipv6.conf.all.forwarding \
           net.ipv4.ip_forward net.netfilter.nf_conntrack_max; do
  want="${WANT[$key]}"
  got=$(sysctl -n "$key" 2>/dev/null || echo "")
  check "running system: $key = $want" "$want" "$got"
done

echo
# persistence: the value must be written somewhere sysctl reads at boot
for key in net.bridge.bridge-nf-call-iptables net.ipv6.conf.all.forwarding \
           net.ipv4.ip_forward net.netfilter.nf_conntrack_max; do
  want="${WANT[$key]}"
  FOUND=$(grep -rhE "^[[:space:]]*${key}[[:space:]]*=[[:space:]]*${want}[[:space:]]*$" \
            /etc/sysctl.conf /etc/sysctl.d/ /usr/lib/sysctl.d/ 2>/dev/null | head -1)
  WHERE=$(grep -rlE "^[[:space:]]*${key}[[:space:]]*=[[:space:]]*${want}[[:space:]]*$" \
            /etc/sysctl.conf /etc/sysctl.d/ 2>/dev/null | head -1)
  if [ -n "$FOUND" ]; then
    pass "persists across reboot: $key  (in ${WHERE:-a sysctl config})"
  else
    fail "persists across reboot: $key  ${YELLOW}not found in /etc/sysctl.conf or /etc/sysctl.d/${NC}"
  fi
done

summary
