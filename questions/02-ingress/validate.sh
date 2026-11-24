#!/usr/bin/env bash
# Question 2 - Ingress : check the answer
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/common.sh"
require_python

NS=sound-repeater
NAME=echo

echo "Checking Question 2 - Ingress"
echo

if ! kubectl get ingress $NAME -n $NS >/dev/null 2>&1; then
  fail "Ingress '$NAME' exists in namespace '$NS'"; summary; exit 1
fi
pass "Ingress '$NAME' exists in namespace '$NS'"

REPORT=$(kubectl get ingress $NAME -n $NS -o json | python3 -I -c '
import json, sys
try:
    ing = json.load(sys.stdin)
except Exception:
    sys.exit(0)
spec = ing.get("spec", {})
print("class=" + str(spec.get("ingressClassName") or ""))
rules = spec.get("rules") or []
print("nrules=" + str(len(rules)))
if rules:
    r = rules[0]
    print("host=" + str(r.get("host") or ""))
    paths = ((r.get("http") or {}).get("paths") or [])
    if paths:
        p = paths[0]
        print("path=" + str(p.get("path") or ""))
        b = (p.get("backend") or {}).get("service") or {}
        print("svc=" + str(b.get("name") or ""))
        print("port=" + str((b.get("port") or {}).get("number") or ""))
')

check "ingressClassName is edge-proxy" "edge-proxy" "$(field "$REPORT" class)"
check "host is example.org"            "example.org" "$(field "$REPORT" host)"
check "path is /echo"                  "/echo"       "$(field "$REPORT" path)"
check "backend Service is echoserver-service" "echoserver-service" "$(field "$REPORT" svc)"
check "backend Service port is 8080"   "8080"        "$(field "$REPORT" port)"

# Does the rule lead to a real, ready Pod? Ask the API directly (EndpointSlices)
# instead of parsing 'kubectl describe', whose layout shifts the backend line
# around (the host gets its own line when a path sits beneath it).
SVC=$(field "$REPORT" svc)
EPS=$(kubectl get endpointslices -n $NS -l "kubernetes.io/service-name=${SVC:-none}" -o json 2>/dev/null \
  | python3 -I -c '
import json, sys
try:
    items = json.load(sys.stdin).get("items", [])
except Exception:
    sys.exit(0)
out = []
for s in items:
    ports = [str(p.get("port")) for p in s.get("ports") or [] if p.get("port")]
    for e in s.get("endpoints") or []:
        if (e.get("conditions") or {}).get("ready", True) is False:
            continue
        for a in e.get("addresses") or []:
            out.append(a + ":" + (ports[0] if ports else "?"))
print(" ".join(out))
' 2>/dev/null)
if [ -n "$EPS" ]; then
  pass "the rule resolves to a real Pod endpoint  ($SVC:8080 -> $EPS)"
else
  fail "the rule resolves to a real Pod endpoint  ${YELLOW}Service '${SVC:-?}' has no ready endpoints - check the Service name and that its Pod is Running${NC}"
fi

ADDR=$(kubectl get ingress $NAME -n $NS -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [ -n "$ADDR" ]; then
  pass "the controller assigned an ADDRESS ($ADDR)"
else
  fail "the controller assigned an ADDRESS  ${YELLOW}wait ~20s and check again${NC}"
fi

# the end-to-end test from the task
CODE=$(curl -o /dev/null -s -w '%{http_code}' --max-time 8 http://example.org/echo 2>/dev/null)
if [ "$CODE" = "200" ]; then
  pass "curl http://example.org/echo returns 200"
else
  fail "curl http://example.org/echo returns 200  ${YELLOW}got:${NC} ${CODE:-no response}"
  echo
  echo "  Two things to check, in this order:"
  echo "    grep example.org /etc/hosts"
  echo "    curl -o /dev/null -s -w '%{http_code}\\n' -H 'Host: example.org' http://localhost/echo"
  echo "  If the second returns 200 but the first did not, it is DNS, not your Ingress."
fi

summary
