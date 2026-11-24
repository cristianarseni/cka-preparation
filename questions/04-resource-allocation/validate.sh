#!/usr/bin/env bash
# Question 4 - Resource allocation : check the answer
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/common.sh"
require_python

NS=relative-fawn
NAME=wordpress

echo "Checking Question 4 - Resource allocation"
echo

if ! kubectl get deploy "$NAME" -n "$NS" >/dev/null 2>&1; then
  fail "Deployment '$NAME' exists in namespace '$NS'"
  summary; exit 1
fi
pass "Deployment '$NAME' exists in namespace '$NS'"

check "spec.replicas is 3" "3" "$(kubectl get deploy $NAME -n $NS -o jsonpath='{.spec.replicas}')"
READY=$(kubectl get deploy $NAME -n $NS -o jsonpath='{.status.readyReplicas}')
check "3 replicas are ready" "3" "${READY:-0}"

DEPLOY_JSON=$(kubectl get deploy "$NAME" -n "$NS" -o json)
NODE=$(kubectl get pods -n "$NS" -l app=wordpress -o jsonpath='{.items[0].spec.nodeName}' 2>/dev/null)

if [ -z "$NODE" ]; then
  fail "wordpress Pods are scheduled onto a node"
  summary; exit 1
fi
pass "wordpress Pods are scheduled (node: $NODE)"

NODE_JSON=$(kubectl get node "$NODE" -o json)
# requests of every OTHER pod already running on that node
OTHER_JSON=$(kubectl get pods -A --field-selector "spec.nodeName=$NODE" -o json)

REPORT=$(python3 -I -c '
import json, sys, re

def cpu(v):
    if not v: return 0.0
    v = str(v)
    return float(v[:-1]) / 1000.0 if v.endswith("m") else float(v)

UNITS = {"Ki":2**10,"Mi":2**20,"Gi":2**30,"Ti":2**40,
         "K":10**3,"M":10**6,"G":10**9,"T":10**12,"k":10**3}
def mem(v):
    if not v: return 0.0
    v = str(v)
    m = re.match(r"^(\d+(?:\.\d+)?)([A-Za-z]*)$", v)
    if not m: return 0.0
    return float(m.group(1)) * UNITS.get(m.group(2), 1)

deploy = json.load(open(sys.argv[1]))
node   = json.load(open(sys.argv[2]))
others = json.load(open(sys.argv[3]))
NS     = sys.argv[4]

spec = deploy["spec"]["template"]["spec"]
mains = spec.get("containers") or []
inits = spec.get("initContainers") or []

missing = []
for c in mains + inits:
    req = (c.get("resources") or {}).get("requests") or {}
    if not req.get("cpu"):    missing.append(c["name"] + "/cpu")
    if not req.get("memory"): missing.append(c["name"] + "/memory")

def req_of(c, key):
    return ((c.get("resources") or {}).get("requests") or {}).get(key)

# a Pod reserves max(largest init container, sum of main containers)
pod_cpu = max([sum(cpu(req_of(c,"cpu")) for c in mains)] + [cpu(req_of(c,"cpu")) for c in inits] or [0])
pod_mem = max([sum(mem(req_of(c,"memory")) for c in mains)] + [mem(req_of(c,"memory")) for c in inits] or [0])

alloc_cpu = cpu(node["status"]["allocatable"]["cpu"])
alloc_mem = mem(node["status"]["allocatable"]["memory"])

other_cpu = other_mem = 0.0
for p in others.get("items", []):
    if p["metadata"]["namespace"] == NS and p["metadata"].get("labels", {}).get("app") == "wordpress":
        continue
    if p.get("status", {}).get("phase") in ("Succeeded", "Failed"):
        continue
    ps = p["spec"]
    pm = ps.get("containers") or []
    pi = ps.get("initContainers") or []
    other_cpu += max([sum(cpu(req_of(c,"cpu")) for c in pm)] + [cpu(req_of(c,"cpu")) for c in pi] or [0])
    other_mem += max([sum(mem(req_of(c,"memory")) for c in pm)] + [mem(req_of(c,"memory")) for c in pi] or [0])

total_cpu = pod_cpu * 3 + other_cpu
total_mem = pod_mem * 3 + other_mem

out = {
  "missing": ",".join(missing),
  "pod_cpu_m": round(pod_cpu * 1000),
  "pod_mem_mi": round(pod_mem / 2**20),
  "alloc_cpu_m": round(alloc_cpu * 1000),
  "alloc_mem_mi": round(alloc_mem / 2**20),
  "cpu_pct": round(total_cpu / alloc_cpu * 100) if alloc_cpu else 0,
  "mem_pct": round(total_mem / alloc_mem * 100) if alloc_mem else 0,
}
for k, v in out.items():
    print(f"{k}={v}")
' <(printf '%s' "$DEPLOY_JSON") <(printf '%s' "$NODE_JSON") <(printf '%s' "$OTHER_JSON") "$NS" 2>/dev/null)

R_missing=$(field "$REPORT" missing)
R_pod_cpu_m=$(field "$REPORT" pod_cpu_m)
R_pod_mem_mi=$(field "$REPORT" pod_mem_mi)
R_alloc_cpu_m=$(field "$REPORT" alloc_cpu_m)
R_alloc_mem_mi=$(field "$REPORT" alloc_mem_mi)
R_cpu_pct=$(field "$REPORT" cpu_pct)
R_mem_pct=$(field "$REPORT" mem_pct)

if [ -n "${R_missing:-}" ]; then
  fail "every container has cpu and memory requests  ${YELLOW}missing:${NC} ${R_missing}"
else
  pass "every container has cpu and memory requests"
fi

echo
echo "  node $NODE allocatable: ${R_alloc_cpu_m:-?}m CPU / ${R_alloc_mem_mi:-?}Mi memory"
echo "  each wordpress Pod reserves: ${R_pod_cpu_m:-?}m CPU / ${R_pod_mem_mi:-?}Mi memory"
echo "  node now committed: ${R_cpu_pct:-?}% CPU / ${R_mem_pct:-?}% memory (all pods included)"
echo

for res in cpu mem; do
  label=$([ $res = cpu ] && echo CPU || echo memory)
  pct_var="R_${res}_pct"; pct=${!pct_var:-0}
  if [ "$pct" -ge 40 ] && [ "$pct" -le 95 ]; then
    pass "$label requests divide the node fairly (${pct}% committed, 40-95% expected)"
  elif [ "$pct" -lt 40 ]; then
    fail "$label requests are too small  ${YELLOW}only ${pct}% of the node is committed${NC} - the task asks you to divide the node among the 3 Pods"
  else
    fail "$label requests leave no overhead  ${YELLOW}${pct}% of the node is committed${NC} - the task asks for headroom to keep the node stable"
  fi
done

summary
