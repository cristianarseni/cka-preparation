#!/usr/bin/env bash
# Question 14 - etcd : check the answer
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/common.sh"
require_python

M=/etc/kubernetes/manifests

echo "Checking Question 14 - etcd / control plane repair"
echo

# --- fault 1: the apiserver's etcd endpoint ----------------------------------
if [ -r "$M/kube-apiserver.yaml" ]; then
  ETCD=$(grep -o '\-\-etcd-servers=[^ ]*' "$M/kube-apiserver.yaml" | head -1)
  if printf '%s' "$ETCD" | grep -q ':2379'; then
    pass "kube-apiserver points at etcd's client port 2379  ($ETCD)"
  else
    fail "kube-apiserver points at etcd's client port 2379  ${YELLOW}got:${NC} ${ETCD:-not found}"
  fi
else
  echo -e "  ${YELLOW}SKIP${NC}  cannot read $M (run as root on the control-plane node)"
fi

# --- fault 2: the scheduler's cpu request ------------------------------------
if [ -r "$M/kube-scheduler.yaml" ]; then
  CPU=$(grep -A3 'requests:' "$M/kube-scheduler.yaml" | grep -o 'cpu: .*' | head -1 | sed 's/cpu: *//')
  MILLI=$(printf '%s' "$CPU" | python3 -I -c '
import sys
v = sys.stdin.read().strip().strip("\"'"'"'")
try:
    print(int(float(v[:-1])) if v.endswith("m") else int(float(v) * 1000))
except Exception:
    print(-1)')
  if [ "$MILLI" -gt 0 ] && [ "$MILLI" -le 1000 ]; then
    pass "kube-scheduler asks for a sane CPU request  (cpu: $CPU)"
  else
    fail "kube-scheduler asks for a sane CPU request  ${YELLOW}got:${NC} cpu: ${CPU:-not found}"
  fi
fi

# --- is the cluster actually back? -------------------------------------------
echo
if ! kubectl get nodes >/dev/null 2>&1; then
  fail "the API server responds to kubectl"
  echo
  echo "  Start here:"
  echo "    sudo journalctl -u kubelet --no-pager -l | tail -30"
  echo "    sudo crictl ps -a | grep -E 'apiserver|etcd'"
  summary; exit 1
fi
pass "the API server responds to kubectl"

NOTREADY=$(kubectl get nodes --no-headers 2>/dev/null | grep -cv ' Ready' || true)
if [ "${NOTREADY:-1}" -eq 0 ]; then
  pass "all nodes are Ready"
else
  fail "all nodes are Ready  ${YELLOW}${NOTREADY} not Ready${NC}"
fi

BAD=$(kubectl get pods -n kube-system --no-headers 2>/dev/null \
      | grep -vE '(Running|Completed)' | awk '{print $1}' | paste -sd' ' || true)
if [ -z "$BAD" ]; then
  pass "every Pod in kube-system is Running"
else
  fail "every Pod in kube-system is Running  ${YELLOW}not healthy:${NC} $BAD"
fi

for c in kube-apiserver kube-scheduler kube-controller-manager etcd; do
  N=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep "^$c" | grep -c Running || true)
  if [ "${N:-0}" -ge 1 ]; then
    pass "$c is Running"
  else
    fail "$c is Running"
  fi
done

summary
