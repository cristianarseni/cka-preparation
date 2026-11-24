#!/usr/bin/env bash
# Question 12 - Gateway API : check the answer
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/common.sh"
require_python

HOST=gateway.web.k8s.local

echo "Checking Question 12 - Migrate Ingress to Gateway API"
echo

# ------------------------------------------------------------------- Gateway
if ! kubectl get gateway web-gateway >/dev/null 2>&1; then
  fail "Gateway 'web-gateway' exists"; summary; exit 1
fi
pass "Gateway 'web-gateway' exists"

G=$(kubectl get gateway web-gateway -o json | python3 -I -c '
import json, sys
try:
    spec = json.load(sys.stdin).get("spec", {})
except Exception:
    sys.exit(0)
print("class=" + str(spec.get("gatewayClassName") or ""))
ls = spec.get("listeners") or []
print("nlisteners=" + str(len(ls)))
https = [l for l in ls if str(l.get("protocol","")).upper() == "HTTPS"] or ls
if https:
    l = https[0]
    print("proto=" + str(l.get("protocol") or ""))
    print("port=" + str(l.get("port") or ""))
    print("hostname=" + str(l.get("hostname") or ""))
    tls = l.get("tls") or {}
    print("tlsmode=" + str(tls.get("mode") or ""))
    refs = tls.get("certificateRefs") or []
    print("cert=" + (str(refs[0].get("name")) if refs else ""))
')

check "gatewayClassName is nginx"        "nginx"       "$(field "$G" class)"
check "the listener protocol is HTTPS"   "HTTPS"       "$(field "$G" proto)"
check "the listener port is 443"         "443"         "$(field "$G" port)"
check "the listener hostname is $HOST"   "$HOST"       "$(field "$G" hostname)"
check "TLS mode is Terminate"            "Terminate"   "$(field "$G" tlsmode)"
check "it references the existing 'web-tls' Secret" "web-tls" "$(field "$G" cert)"

# ----------------------------------------------------------------- HTTPRoute
if ! kubectl get httproute web-route >/dev/null 2>&1; then
  fail "HTTPRoute 'web-route' exists"; summary; exit 1
fi
pass "HTTPRoute 'web-route' exists"

R=$(kubectl get httproute web-route -o json | python3 -I -c '
import json, sys
try:
    spec = json.load(sys.stdin).get("spec", {})
except Exception:
    sys.exit(0)
parents = spec.get("parentRefs") or []
print("parent=" + (str(parents[0].get("name")) if parents else ""))
print("hostnames=" + ",".join(spec.get("hostnames") or []))
rules = spec.get("rules") or []
if rules:
    br = rules[0].get("backendRefs") or []
    if br:
        print("backend=" + str(br[0].get("name") or ""))
        print("bport=" + str(br[0].get("port") or ""))
')

check "parentRef points at 'web-gateway'" "web-gateway" "$(field "$R" parent)"
if printf '%s' "$(field "$R" hostnames)" | grep -q "$HOST"; then
  pass "the hostname is $HOST"
else
  fail "the hostname is $HOST  ${YELLOW}got:${NC} $(field "$R" hostnames)"
fi
check "the backend Service is 'web'"      "web" "$(field "$R" backend)"
check "the backend port is 80"            "80"  "$(field "$R" bport)"

# ------------------------------------------------------------- Ingress gone
if kubectl get ingress web >/dev/null 2>&1; then
  fail "the old Ingress 'web' was deleted  ${YELLOW}still there - the last step of the task${NC}"
else
  pass "the old Ingress 'web' was deleted"
fi

# the Secret must survive - the Gateway depends on it
if kubectl get secret web-tls >/dev/null 2>&1; then
  pass "the 'web-tls' Secret still exists"
else
  fail "the 'web-tls' Secret still exists  ${YELLOW}deleting it breaks HTTPS${NC}"
fi

echo
echo -e "  ${YELLOW}NOTE${NC}  no Gateway controller is running in this practice cluster, so the"
echo "        Gateway will stay 'not programmed' and curl will not work. The exam"
echo "        grades the objects, which is what is checked above."

summary
