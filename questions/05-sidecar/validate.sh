#!/usr/bin/env bash
# Question 5 - Sidecar : check the answer
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/common.sh"
require_python

NAME=synergy-leverager

echo "Checking Question 5 - Sidecar"
echo

if ! kubectl get deploy "$NAME" >/dev/null 2>&1; then
  fail "Deployment '$NAME' exists"
  summary; exit 1
fi
pass "Deployment '$NAME' exists"

J=$(kubectl get deploy "$NAME" -o json)

REPORT=$(printf '%s' "$J" | python3 -I -c '
import json, sys
try:
    spec = json.load(sys.stdin)["spec"]["template"]["spec"]
except Exception:
    sys.exit(0)
containers = {c["name"]: c for c in spec.get("containers") or []}
volumes    = {v["name"]: v for v in spec.get("volumes") or []}

side = containers.get("sidecar")
orig = containers.get("monitor")

def mount_at(c, path):
    for m in (c or {}).get("volumeMounts") or []:
        if m.get("mountPath","").rstrip("/") == path:
            return m.get("name","")
    return ""

out = {}
out["has_sidecar"]  = "yes" if side else "no"
out["has_monitor"]  = "yes" if orig else "no"
out["side_image"]   = (side or {}).get("image","")
out["cmd"]          = " ".join((side or {}).get("command") or []) + " " + " ".join((side or {}).get("args") or [])
out["side_vol"]     = mount_at(side, "/var/log")
out["orig_vol"]     = mount_at(orig, "/var/log")
out["orig_image"]   = (orig or {}).get("image","")
out["vol_declared"] = "yes" if out["side_vol"] and out["side_vol"] in volumes else "no"
out["n_containers"] = str(len(containers))
for k, v in out.items():
    print(f"{k}={v}")
')
R_has_sidecar=$(field "$REPORT" has_sidecar)
R_has_monitor=$(field "$REPORT" has_monitor)
R_side_image=$(field "$REPORT" side_image)
R_cmd=$(field "$REPORT" cmd)
R_side_vol=$(field "$REPORT" side_vol)
R_orig_vol=$(field "$REPORT" orig_vol)
R_orig_image=$(field "$REPORT" orig_image)
R_vol_declared=$(field "$REPORT" vol_declared)
R_n_containers=$(field "$REPORT" n_containers)

check "a container named 'sidecar' was added"      "yes"            "$R_has_sidecar"
check "sidecar image is busybox:stable"            "busybox:stable" "$R_side_image"

CMD="$R_cmd"
if [[ "$CMD" == */bin/sh* && "$CMD" == *-c* ]]; then
  pass "sidecar runs /bin/sh -c"
else
  fail "sidecar runs /bin/sh -c  ${YELLOW}got:${NC} ${CMD:-<empty>}"
fi
if [[ "$CMD" == *"tail"* && "$CMD" == *"-n+1"* && "$CMD" == *"-f"* && "$CMD" == *"/var/log/synergy-leverager.log"* ]]; then
  pass "sidecar command is  tail -n+1 -f /var/log/synergy-leverager.log"
else
  fail "sidecar command is  tail -n+1 -f /var/log/synergy-leverager.log  ${YELLOW}got:${NC} ${CMD:-<empty>}"
fi

if [ -n "$R_side_vol" ]; then
  pass "sidecar mounts a volume at /var/log (volume: $R_side_vol)"
else
  fail "sidecar mounts a volume at /var/log"
fi
check "that volume is declared on the Pod"          "yes" "$R_vol_declared"

if [ -n "$R_orig_vol" ] && [ "$R_orig_vol" = "$R_side_vol" ]; then
  pass "the original container mounts the SAME volume at /var/log"
else
  fail "the original container mounts the SAME volume at /var/log  ${YELLOW}sidecar uses '${R_side_vol:-none}', monitor uses '${R_orig_vol:-none}'${NC}"
fi

check "the original container 'monitor' is still there" "yes"            "$R_has_monitor"
check "the original container image is unchanged"       "busybox:stable" "$R_orig_image"
check "the Pod has exactly 2 containers"                "2"              "$R_n_containers"

# rollout and real log output
if kubectl rollout status deploy "$NAME" --timeout=90s >/dev/null 2>&1; then
  pass "rollout completed"
else
  fail "rollout completed  ${YELLOW}run: kubectl rollout status deploy $NAME${NC}"
fi

POD=$(kubectl get pods -l app="$NAME" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$POD" ] && kubectl logs "$POD" -c sidecar --tail=5 2>/dev/null | grep -q "synergy-leverager event"; then
  pass "kubectl logs -c sidecar streams the log file"
else
  fail "kubectl logs -c sidecar streams the log file  ${YELLOW}(give it ~10s after rollout, then retry)${NC}"
fi

summary
