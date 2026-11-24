#!/usr/bin/env bash
# Question 7 - StorageClass : check the answer
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/common.sh"
require_python

SC=local-path
ANN='storageclass.kubernetes.io/is-default-class'

echo "Checking Question 7 - StorageClass"
echo

if ! kubectl get storageclass "$SC" >/dev/null 2>&1; then
  fail "StorageClass '$SC' exists"
  echo
  echo "  Note: the name must be exactly '$SC' - not 'local-storage'."
  summary; exit 1
fi
pass "StorageClass '$SC' exists"

check "provisioner is rancher.io/local-path" "rancher.io/local-path" \
      "$(kubectl get sc $SC -o jsonpath='{.provisioner}')"
check "volumeBindingMode is WaitForFirstConsumer" "WaitForFirstConsumer" \
      "$(kubectl get sc $SC -o jsonpath='{.volumeBindingMode}')"
check "marked as the default StorageClass" "true" \
      "$(kubectl get sc $SC -o jsonpath="{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}")"

# exactly one default - a cluster with two defaults is a misconfiguration
DEFAULTS=$(kubectl get sc -o json | python3 -I -c '
import json,sys
try: _d = json.load(sys.stdin)
except Exception: sys.exit(0)
out=[s["metadata"]["name"] for s in _d["items"]
     if (s["metadata"].get("annotations") or {}).get("storageclass.kubernetes.io/is-default-class")=="true"]
print(",".join(out))')
if [ "$DEFAULTS" = "$SC" ]; then
  pass "it is the ONLY default StorageClass"
else
  fail "it is the ONLY default StorageClass  ${YELLOW}defaults found:${NC} ${DEFAULTS:-none}"
fi

# the task forbids touching the existing PVC / Deployment
STATE="$STATE_DIR/07-storageclass.state"
if [ -f "$STATE" ]; then
  WANT_PVC=$(sed -n 1p "$STATE"); WANT_GEN=$(sed -n 2p "$STATE")
  GOT_PVC=$(kubectl get pvc archive-data -n sc-workload -o jsonpath='{.spec.storageClassName}|{.spec.resources.requests.storage}' 2>/dev/null)
  GOT_GEN=$(kubectl get deploy archive -n sc-workload -o jsonpath='{.metadata.generation}' 2>/dev/null)
  check "existing PVC 'archive-data' was not modified"  "$WANT_PVC" "$GOT_PVC"
  check "existing Deployment 'archive' was not modified" "$WANT_GEN" "$GOT_GEN"
else
  echo -e "  ${YELLOW}SKIP${NC}  cannot check the existing PVC/Deployment - run ./run.sh 7 first"
fi

summary
