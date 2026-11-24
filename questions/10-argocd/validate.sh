#!/usr/bin/env bash
# Question 10 - Argo CD : check the answer
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/common.sh"

NS=argocd
TPL=/home/candidate/argo-helm.yaml

echo "Checking Question 10 - Argo CD"
echo

command -v helm >/dev/null 2>&1 || { echo -e "  ${RED}ERROR${NC}  helm is not installed - run ./run.sh 10 first"; exit 2; }

# --- the repo -----------------------------------------------------------------
REPO_URL=$(helm repo list -o json 2>/dev/null | python3 -I -c '
import json,sys
try: rs=json.load(sys.stdin)
except Exception: rs=[]
for r in rs:
    if r.get("name")=="argo": print(r.get("url","")); break
')
check "helm repo 'argo' points at the official chart repo" \
      "https://argoproj.github.io/argo-helm" "$REPO_URL"

# --- the template file --------------------------------------------------------
if [ ! -s "$TPL" ]; then
  fail "$TPL exists and is not empty"
else
  pass "$TPL exists and is not empty"

  if grep -q 'kind: Deployment' "$TPL" && grep -qi 'argocd' "$TPL"; then
    pass "it contains rendered Argo CD manifests"
  else
    fail "it contains rendered Argo CD manifests  ${YELLOW}check the file content${NC}"
  fi

  if grep -q 'kind: CustomResourceDefinition' "$TPL"; then
    fail "the template has NO CRDs in it  ${YELLOW}crds.install=false was not applied${NC}"
  else
    pass "the template has no CRDs in it (crds.install=false worked)"
  fi

  if grep -q "namespace: $NS" "$TPL"; then
    pass "it was templated for the '$NS' namespace"
  else
    fail "it was templated for the '$NS' namespace  ${YELLOW}--namespace $NS missing?${NC}"
  fi
fi

# --- the release --------------------------------------------------------------
REL=$(helm list -n $NS -o json 2>/dev/null | python3 -I -c '
import json,sys
try: rs=json.load(sys.stdin)
except Exception: rs=[]
for r in rs:
    if r.get("name")=="argocd":
        print("chart=" + str(r.get("chart","")))
        print("status=" + str(r.get("status","")))
        print("ns=" + str(r.get("namespace","")))
        break
')

if [ -z "$REL" ]; then
  fail "a helm release named 'argocd' exists in namespace '$NS'"
  echo
  echo "  helm list -n $NS   shows nothing. Templating is not installing -"
  echo "  'helm template' only prints YAML, it changes nothing in the cluster."
  summary; exit 1
fi
pass "a helm release named 'argocd' exists in namespace '$NS'"

check "the chart version is 7.7.3" "argo-cd-7.7.3" "$(field "$REL" chart)"
check "the release status is deployed" "deployed" "$(field "$REL" status)"

# --- did it actually come up? -------------------------------------------------
if kubectl get deploy -n $NS 2>/dev/null | grep -q argocd-server; then
  pass "the argocd-server Deployment was created"
else
  fail "the argocd-server Deployment was created  ${YELLOW}kubectl get all -n $NS${NC}"
fi

RUNNING=$(kubectl get pods -n $NS --no-headers 2>/dev/null | grep -c 'Running' || true)
if [ "${RUNNING:-0}" -ge 1 ]; then
  pass "$RUNNING Argo CD Pod(s) are Running"
else
  fail "Argo CD Pods are Running  ${YELLOW}they may still be pulling images - wait and retry${NC}"
fi

summary
