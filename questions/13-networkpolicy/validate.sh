#!/usr/bin/env bash
# Question 13 - NetworkPolicy : check the answer
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/common.sh"
require_python

echo "Checking Question 13 - NetworkPolicy"
echo

# --- the default deny must survive -------------------------------------------
if kubectl get netpol default-deny -n backend >/dev/null 2>&1; then
  pass "the default-deny NetworkPolicy is still there"
else
  fail "the default-deny NetworkPolicy is still there  ${YELLOW}deleting it scores zero${NC}"
fi

# --- the samples must be untouched -------------------------------------------
STATE="$STATE_DIR/13-networkpolicy.state"
if [ -f "$STATE" ] && [ -d "$HOME/netpol" ]; then
  if ( cd "$HOME/netpol" && md5sum -c --quiet "$STATE" ) >/dev/null 2>&1; then
    pass "the sample files in ~/netpol were not modified"
  else
    fail "the sample files in ~/netpol were not modified  ${YELLOW}the task says do not edit them${NC}"
  fi
else
  echo -e "  ${YELLOW}SKIP${NC}  cannot check the sample files - run ./run.sh 13 first"
fi

# --- exactly one policy was applied, and it is the right one -----------------
APPLIED=$(kubectl get netpol -n backend -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | grep -v '^default-deny$' || true)
COUNT=$(printf '%s' "$APPLIED" | grep -c . || true)

if [ "$COUNT" -eq 1 ]; then
  pass "exactly one sample policy was applied ($APPLIED)"
elif [ "$COUNT" -eq 0 ]; then
  fail "exactly one sample policy was applied  ${YELLOW}none found${NC}"
  summary; exit 1
else
  fail "exactly one sample policy was applied  ${YELLOW}found $COUNT:${NC} $(printf '%s' "$APPLIED" | tr '\n' ' ')"
fi

case "$APPLIED" in
  allow-frontend-to-backend)
    pass "the chosen policy is the least permissive one that still works" ;;
  allow-all-ingress)
    fail "the chosen policy is the least permissive one that still works  ${YELLOW}network-policy-1 allows ingress from ANY pod in ANY namespace${NC}" ;;
  allow-cidr-ingress)
    fail "the chosen policy is the least permissive one that still works  ${YELLOW}network-policy-3 allows the 0.0.0.0/0 CIDR - the whole network${NC}" ;;
  *)
    fail "the chosen policy is one of the provided samples  ${YELLOW}got:${NC} ${APPLIED:-none}" ;;
esac

# --- does it actually work? ---------------------------------------------------
FPOD=$(kubectl get pod -n frontend -l app=frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$FPOD" ]; then
  if kubectl exec -n frontend "$FPOD" -- timeout 8 wget -q -O- --timeout=6 http://backend.backend.svc.cluster.local >/dev/null 2>&1; then
    pass "a frontend Pod CAN reach the backend Service"
  else
    fail "a frontend Pod CAN reach the backend Service  ${YELLOW}kubectl exec -n frontend $FPOD -- wget -O- http://backend.backend${NC}"
  fi
else
  fail "a frontend Pod exists to test with"
fi

# a pod outside the frontend namespace must NOT get through
kubectl delete pod netpol-probe -n default --ignore-not-found --wait=true >/dev/null 2>&1
if kubectl run netpol-probe -n default --image=busybox:stable --restart=Never \
      --command -- sh -c "sleep 60" >/dev/null 2>&1 \
   && kubectl wait --for=condition=Ready pod/netpol-probe -n default --timeout=60s >/dev/null 2>&1; then
  if kubectl exec netpol-probe -n default -- timeout 8 wget -q -O- --timeout=6 http://backend.backend.svc.cluster.local >/dev/null 2>&1; then
    echo -e "  ${YELLOW}WARN${NC}  a Pod outside 'frontend' also reached the backend."
    echo "         Either the policy is too permissive, or this cluster's CNI does not"
    echo "         enforce NetworkPolicy at all (flannel does not; Calico does)."
  else
    pass "a Pod outside 'frontend' is correctly blocked"
  fi
  kubectl delete pod netpol-probe -n default --ignore-not-found --wait=false >/dev/null 2>&1
else
  echo -e "  ${YELLOW}SKIP${NC}  could not start a probe Pod to test the blocked path"
fi

summary
