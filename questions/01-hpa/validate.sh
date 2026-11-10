#!/usr/bin/env bash
# Question 1 - HPA : check the answer
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/common.sh"

NS=autoscale
NAME=apache-server

echo "Checking Question 1 - HPA"
echo

if ! kubectl get hpa "$NAME" -n "$NS" >/dev/null 2>&1; then
  fail "HPA '$NAME' exists in namespace '$NS'"
  echo
  echo "  Nothing else can be checked until the HPA exists."
  summary
  exit 1
fi
pass "HPA '$NAME' exists in namespace '$NS'"

# Read through the v2 API so behavior and metrics are visible.
HPA_JSON=$(kubectl get hpa.v2.autoscaling "$NAME" -n "$NS" -o json 2>/dev/null) \
  || HPA_JSON=$(kubectl get hpa "$NAME" -n "$NS" -o json 2>/dev/null)

# get <dotted.path>   e.g. get spec.minReplicas
get() {
  printf '%s' "$HPA_JSON" | python3 -I -c '
import json, sys
node = json.load(sys.stdin)
for key in sys.argv[1].split("."):
    if not isinstance(node, dict) or key not in node:
        print(""); sys.exit()
    node = node[key]
print("" if node is None else node)
' "$1" 2>/dev/null
}

# the cpu target lives in a different place in v1 and v2
cpu_target() {
  local v1; v1=$(get spec.targetCPUUtilizationPercentage)
  if [ -n "$v1" ]; then printf '%s' "$v1"; return; fi
  printf '%s' "$HPA_JSON" | python3 -I -c '
import json, sys
d = json.load(sys.stdin)
for m in d.get("spec", {}).get("metrics") or []:
    r = m.get("resource") or {}
    if r.get("name") == "cpu":
        print((r.get("target") or {}).get("averageUtilization", "") or "")
        break
' 2>/dev/null
}

check "targets kind Deployment"        "Deployment" "$(get spec.scaleTargetRef.kind)"
check "targets Deployment '$NAME'"     "$NAME"      "$(get spec.scaleTargetRef.name)"
check "minReplicas is 1"               "1"          "$(get spec.minReplicas)"
check "maxReplicas is 4"               "4"          "$(get spec.maxReplicas)"
check "CPU target is 50%"              "50"         "$(cpu_target)"
check "scaleDown stabilization is 30s" "30"         "$(get spec.behavior.scaleDown.stabilizationWindowSeconds)"

summary
