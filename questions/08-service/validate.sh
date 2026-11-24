#!/usr/bin/env bash
# Question 8 - Service : check the answer
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/common.sh"
require_python

NS=spline-reticulator

echo "Checking Question 8 - Service"
echo

if ! kubectl get deploy front-end -n $NS >/dev/null 2>&1; then
  fail "Deployment 'front-end' exists in namespace '$NS'"; summary; exit 1
fi
pass "Deployment 'front-end' exists in namespace '$NS'"

PORTS=$(kubectl get deploy front-end -n $NS -o json | python3 -I -c '
import json,sys
try:
    _d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for c in _d["spec"]["template"]["spec"]["containers"]:
    if c["name"]=="nginx":
        for p in c.get("ports") or []:
            print(str(p.get("containerPort")) + "/" + str(p.get("protocol") or "TCP"))
')
if printf '%s' "$PORTS" | grep -qx "80/TCP"; then
  pass "container 'nginx' declares containerPort 80/TCP"
else
  fail "container 'nginx' declares containerPort 80/TCP  ${YELLOW}found:${NC} ${PORTS:-none}"
fi

if ! kubectl get svc front-end-svc -n $NS >/dev/null 2>&1; then
  fail "Service 'front-end-svc' exists in namespace '$NS'"; summary; exit 1
fi
pass "Service 'front-end-svc' exists in namespace '$NS'"

check "Service type is NodePort" "NodePort" \
      "$(kubectl get svc front-end-svc -n $NS -o jsonpath='{.spec.type}')"
check "Service port is 80"       "80" \
      "$(kubectl get svc front-end-svc -n $NS -o jsonpath='{.spec.ports[0].port}')"
check "target port is 80"        "80" \
      "$(kubectl get svc front-end-svc -n $NS -o jsonpath='{.spec.ports[0].targetPort}')"

NODEPORT=$(kubectl get svc front-end-svc -n $NS -o jsonpath='{.spec.ports[0].nodePort}')
if [ -n "$NODEPORT" ]; then
  pass "a nodePort was allocated ($NODEPORT)"
else
  fail "a nodePort was allocated"
fi

EP=$(kubectl get endpoints front-end-svc -n $NS -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
if [ -n "$EP" ]; then
  pass "the Service has backing Pod endpoints ($(printf '%s' "$EP" | wc -w) pods)"
else
  fail "the Service has backing Pod endpoints  ${YELLOW}empty - check the selector matches the Pod labels${NC}"
fi

if [ -n "$NODEPORT" ]; then
  CODE=$(curl -o /dev/null -s -w '%{http_code}' --max-time 5 "http://localhost:${NODEPORT}/" 2>/dev/null)
  if [ "$CODE" = "200" ]; then
    pass "curl http://localhost:${NODEPORT}/ returns 200"
  else
    fail "curl http://localhost:${NODEPORT}/ returns 200  ${YELLOW}got:${NC} ${CODE:-no response}"
  fi
fi

summary
