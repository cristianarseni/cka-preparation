#!/usr/bin/env bash
# Question 11 - PVC MariaDB : check the answer
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/common.sh"
require_python

NS=mariadb

echo "Checking Question 11 - PVC MariaDB"
echo

if ! kubectl get pvc mariadb -n $NS >/dev/null 2>&1; then
  fail "PVC 'mariadb' exists in namespace '$NS'"; summary; exit 1
fi
pass "PVC 'mariadb' exists in namespace '$NS'"

check "access mode is ReadWriteOnce" "ReadWriteOnce" \
      "$(kubectl get pvc mariadb -n $NS -o jsonpath='{.spec.accessModes[0]}')"
check "requested storage is 250Mi"   "250Mi" \
      "$(kubectl get pvc mariadb -n $NS -o jsonpath='{.spec.resources.requests.storage}')"
check "the PVC is Bound"             "Bound" \
      "$(kubectl get pvc mariadb -n $NS -o jsonpath='{.status.phase}')"

BOUND_PV=$(kubectl get pvc mariadb -n $NS -o jsonpath='{.spec.volumeName}')
check "it is bound to the existing PV 'mariadb-pv'" "mariadb-pv" "$BOUND_PV"

# prove the original PV was reused, not deleted and recreated
STATE="$STATE_DIR/11-pvc-mariadb.state"
if [ -f "$STATE" ]; then
  check "that PV is the ORIGINAL one (not recreated)" "$(cat "$STATE")" \
        "$(kubectl get pv mariadb-pv -o jsonpath='{.metadata.uid}' 2>/dev/null)"
else
  echo -e "  ${YELLOW}SKIP${NC}  cannot prove the PV was reused - run ./run.sh 11 first"
fi

check "the PV reclaim policy is still Retain" "Retain" \
      "$(kubectl get pv mariadb-pv -o jsonpath='{.spec.persistentVolumeReclaimPolicy}' 2>/dev/null)"

if ! kubectl get deploy mariadb -n $NS >/dev/null 2>&1; then
  fail "Deployment 'mariadb' exists in namespace '$NS'"; summary; exit 1
fi
pass "Deployment 'mariadb' exists in namespace '$NS'"

CLAIM=$(kubectl get deploy mariadb -n $NS -o json | python3 -I -c '
import json, sys
try:
    vols = json.load(sys.stdin)["spec"]["template"]["spec"].get("volumes") or []
except Exception:
    sys.exit(0)
for v in vols:
    p = v.get("persistentVolumeClaim")
    if p:
        print(p.get("claimName","")); break
')
check "the Deployment uses PVC 'mariadb'" "mariadb" "$CLAIM"

READY=$(kubectl get deploy mariadb -n $NS -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
check "the Deployment has a ready replica" "1" "${READY:-0}"

POD=$(live_pod "$NS" app=mariadb)
if [ -n "$POD" ] && kubectl logs "$POD" -n $NS --tail=30 2>/dev/null | grep -qi "ready for connections"; then
  pass "MariaDB started cleanly on the retained volume"
else
  fail "MariaDB started cleanly on the retained volume  ${YELLOW}check: kubectl logs -n $NS $POD${NC}"
fi

summary
