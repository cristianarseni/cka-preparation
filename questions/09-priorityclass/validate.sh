#!/usr/bin/env bash
# Question 9 - PriorityClass : check the answer
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/common.sh"
require_python

NS=priority
PC=high-priority

echo "Checking Question 9 - PriorityClass"
echo

# Work out the expected value from the cluster, the same way you had to.
# "user-defined" = everything except the built-in system-* classes,
# and excluding high-priority itself.
EXPECTED=$(kubectl get priorityclass -o json | python3 -I -c '
import json, sys
try: _d = json.load(sys.stdin)
except Exception: sys.exit(0)
vals = [p["value"] for p in _d["items"]
        if not p["metadata"]["name"].startswith("system-")
        and p["metadata"]["name"] != "high-priority"]
print(max(vals) - 1 if vals else "")')

if ! kubectl get priorityclass "$PC" >/dev/null 2>&1; then
  fail "PriorityClass '$PC' exists"
  if [ -n "$EXPECTED" ]; then
    echo
    echo "  The highest user-defined value is $((EXPECTED + 1)), so '$PC' should be $EXPECTED."
  fi
  summary; exit 1
fi
pass "PriorityClass '$PC' exists"

if [ -z "$EXPECTED" ]; then
  fail "could not read the existing PriorityClasses from the cluster"
else
  check "value is one less than the highest user-defined class" "$EXPECTED" \
        "$(kubectl get priorityclass $PC -o jsonpath='{.value}')"
fi

GD=$(kubectl get priorityclass $PC -o jsonpath='{.globalDefault}')
if [ "$GD" = "true" ]; then
  fail "it is NOT set as the global default  ${YELLOW}globalDefault=true would apply it to every Pod without a class${NC}"
else
  pass "it is not set as the global default"
fi

check "busybox-logger uses priorityClassName '$PC'" "$PC" \
      "$(kubectl get deploy busybox-logger -n $NS -o jsonpath='{.spec.template.spec.priorityClassName}' 2>/dev/null)"

if kubectl -n $NS rollout status deploy busybox-logger --timeout=90s >/dev/null 2>&1; then
  pass "busybox-logger rolled out successfully"
else
  fail "busybox-logger rolled out successfully"
fi

READY=$(kubectl get deploy busybox-logger -n $NS -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
check "busybox-logger has a ready replica" "1" "${READY:-0}"

# the running Pod must actually carry the priority, not just the template
BPOD=$(live_pod "$NS" app=busybox-logger)
POD_PC=$([ -n "$BPOD" ] && kubectl get pod "$BPOD" -n $NS -o jsonpath='{.spec.priorityClassName}' 2>/dev/null)
check "the running Pod carries the PriorityClass" "$PC" "$POD_PC"

# other Deployments must be untouched
STATE="$STATE_DIR/09-priorityclass.state"
if [ -f "$STATE" ]; then
  i=1
  for d in metrics-collector log-shipper; do
    WANT=$(sed -n "${i}p" "$STATE")
    GOT=$(kubectl get deploy $d -n $NS -o jsonpath='{.metadata.generation}' 2>/dev/null)
    check "Deployment '$d' was left alone" "$WANT" "$GOT"
    i=$((i+1))
  done
else
  echo -e "  ${YELLOW}SKIP${NC}  cannot check the other Deployments - run ./run.sh 9 first"
fi

summary
