#!/usr/bin/env bash
# Question 16 - ConfigMap : check the answer
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/common.sh"
require_python

NS=nginx-static
HOSTNAME=web.k8snginx.local

echo "Checking Question 16 - ConfigMap"
echo

if ! kubectl get configmap nginx-config -n $NS >/dev/null 2>&1; then
  fail "ConfigMap 'nginx-config' exists in namespace '$NS'"; summary; exit 1
fi
pass "ConfigMap 'nginx-config' exists in namespace '$NS'"

CONF=$(kubectl get configmap nginx-config -n $NS -o jsonpath='{.data.nginx\.conf}')
LINE=$(printf '%s' "$CONF" | grep -E '^\s*ssl_protocols' | head -1 | sed 's/^[[:space:]]*//')

if printf '%s' "$LINE" | grep -q 'TLSv1\.2' && printf '%s' "$LINE" | grep -q 'TLSv1\.3'; then
  pass "ssl_protocols allows both TLSv1.2 and TLSv1.3  ($LINE)"
else
  fail "ssl_protocols allows both TLSv1.2 and TLSv1.3  ${YELLOW}found:${NC} ${LINE:-none}"
fi

check "the ConfigMap is immutable" "true" \
      "$(kubectl get configmap nginx-config -n $NS -o jsonpath='{.immutable}')"

# let a 'rollout restart' finish first, so the old Pod is not the one inspected
kubectl -n $NS rollout status deploy nginx-static --timeout=60s >/dev/null 2>&1 || true
READY=$(kubectl get deploy nginx-static -n $NS -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
check "the Deployment has a ready replica" "1" "${READY:-0}"

# The key check: did the RUNNING Pod pick up the new config, or is it still
# serving the old one it loaded at startup?
POD=$(live_pod "$NS" app=nginx-static)
if [ -n "$POD" ]; then
  LIVE=$(kubectl exec -n $NS "$POD" -- grep -E '^\s*ssl_protocols' /etc/nginx/nginx.conf 2>/dev/null | sed 's/^[[:space:]]*//')
  if printf '%s' "$LIVE" | grep -q 'TLSv1\.2'; then
    pass "the running Pod is serving the NEW config"
  else
    fail "the running Pod is serving the NEW config  ${YELLOW}still:${NC} ${LIVE:-unknown}"
    echo "         Editing the ConfigMap does not reload nginx. Run:"
    echo "         k rollout restart deployment nginx-static -n $NS"
  fi
fi

# the end-to-end tests from the task
C12=$(curl -k -o /dev/null -s -w '%{http_code}' --tls-max 1.2 --max-time 8 "https://$HOSTNAME" 2>/dev/null)
if [ "$C12" = "200" ]; then
  pass "curl -k --tls-max 1.2 https://$HOSTNAME returns 200"
else
  fail "curl -k --tls-max 1.2 https://$HOSTNAME returns 200  ${YELLOW}got:${NC} ${C12:-connection refused}"
fi

C13=$(curl -k -o /dev/null -s -w '%{http_code}' --tls-max 1.3 --max-time 8 "https://$HOSTNAME" 2>/dev/null)
if [ "$C13" = "200" ]; then
  pass "TLSv1.3 still works too (you did not replace it)"
else
  fail "TLSv1.3 still works too  ${YELLOW}got:${NC} ${C13:-connection refused}  - the task says keep 1.3 as well"
fi

summary
