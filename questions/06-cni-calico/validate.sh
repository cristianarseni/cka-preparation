#!/usr/bin/env bash
# Question 6 - CNI Calico : check the answer
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/common.sh"

echo "Checking Question 6 - CNI"
echo

if ! kubectl get nodes >/dev/null 2>&1; then
  fail "the API server is reachable"; summary; exit 1
fi

# --- which CNI did they pick? -------------------------------------------------
CNI=none
kubectl get ns tigera-operator >/dev/null 2>&1 && CNI=calico
kubectl get ns kube-flannel    >/dev/null 2>&1 && CNI=flannel

case "$CNI" in
  calico)
    pass "Calico was installed (tigera-operator namespace exists)" ;;
  flannel)
    fail "the CNI can enforce NetworkPolicy  ${YELLOW}Flannel cannot - the Context requires policy enforcement${NC}"
    echo "         Install Calico instead." ;;
  none)
    fail "a CNI was installed"; summary; exit 1 ;;
esac

if [ "$CNI" = calico ]; then
  # the operator alone is not enough - the Installation CR is what deploys Calico
  if kubectl get installation default >/dev/null 2>&1; then
    pass "the Installation resource exists (custom-resources.yaml was applied)"
  else
    fail "the Installation resource exists"
    echo "         The operator on its own deploys nothing. You also need:"
    echo "         k create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/custom-resources.yaml"
  fi

  OPR=$(kubectl get pods -n tigera-operator --no-headers 2>/dev/null | grep -c Running || true)
  if [ "${OPR:-0}" -ge 1 ]; then
    pass "the tigera-operator Pod is Running"
  else
    fail "the tigera-operator Pod is Running"
  fi

  CS=$(kubectl get pods -n calico-system --no-headers 2>/dev/null | grep -c Running || true)
  if [ "${CS:-0}" -ge 2 ]; then
    pass "$CS Pods are Running in calico-system"
  else
    fail "the calico-system Pods are Running  ${YELLOW}found ${CS:-0}, give it a few minutes${NC}"
  fi
fi

# --- is the cluster actually healthy again? -----------------------------------
NOTREADY=$(kubectl get nodes --no-headers 2>/dev/null | grep -cv ' Ready' || true)
if [ "${NOTREADY:-1}" -eq 0 ]; then
  pass "all nodes are Ready"
else
  fail "all nodes are Ready  ${YELLOW}${NOTREADY} not Ready${NC}"
fi

COREDNS=$(kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers 2>/dev/null | grep -c Running || true)
if [ "${COREDNS:-0}" -ge 1 ]; then
  pass "CoreDNS is Running (it stays Pending without a working CNI)"
else
  fail "CoreDNS is Running  ${YELLOW}this is the clearest sign the CNI is not working${NC}"
fi

# --- end to end: can a new Pod get an IP and talk? ---------------------------
kubectl delete pod cni-probe -n default --ignore-not-found --wait=true >/dev/null 2>&1
if kubectl run cni-probe -n default --image=busybox:stable --restart=Never \
     --command -- sh -c "sleep 60" >/dev/null 2>&1 \
   && kubectl wait --for=condition=Ready pod/cni-probe -n default --timeout=90s >/dev/null 2>&1; then
  IP=$(kubectl get pod cni-probe -n default -o jsonpath='{.status.podIP}' 2>/dev/null)
  if [ -n "$IP" ]; then
    pass "a new Pod got a Pod IP ($IP)"
  else
    fail "a new Pod got a Pod IP"
  fi
  if kubectl exec cni-probe -n default -- timeout 8 nslookup kubernetes.default >/dev/null 2>&1; then
    pass "that Pod can resolve cluster DNS - networking works end to end"
  else
    fail "that Pod can resolve cluster DNS"
  fi
  kubectl delete pod cni-probe -n default --ignore-not-found --wait=false >/dev/null 2>&1
else
  fail "a test Pod can start and become Ready  ${YELLOW}pods stay Pending without a CNI${NC}"
fi

summary
