#!/usr/bin/env bash
# Question 15 - CRDs : check the answer
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/common.sh"

R=/home/candidate/resources.yaml
S=/home/candidate/subject.yaml

echo "Checking Question 15 - CRDs"
echo

# ---------------------------------------------------------------- resources
if [ ! -s "$R" ]; then
  fail "$R exists and is not empty"
else
  pass "$R exists and is not empty"

  MISSING=""
  for crd in certificates.cert-manager.io certificaterequests.cert-manager.io \
             issuers.cert-manager.io clusterissuers.cert-manager.io \
             orders.acme.cert-manager.io challenges.acme.cert-manager.io; do
    grep -q "$crd" "$R" || MISSING="$MISSING $crd"
  done
  if [ -z "$MISSING" ]; then
    pass "it lists all 6 cert-manager CRDs"
  else
    fail "it lists all 6 cert-manager CRDs  ${YELLOW}missing:${NC}$MISSING"
  fi

  if grep -qE '^(apiVersion|kind):' "$R" || grep -q 'kind: CustomResourceDefinition' "$R"; then
    fail "it uses kubectl's DEFAULT output format  ${YELLOW}this looks like -o yaml${NC}"
  elif head -1 "$R" | grep -q '^{'; then
    fail "it uses kubectl's DEFAULT output format  ${YELLOW}this looks like -o json${NC}"
  else
    pass "it uses kubectl's default (table) output format"
  fi

  # grep -c prints 0 AND exits 1 on no match, so use '|| true', not '|| echo 0'
  NONCM=$(grep -cE '^[a-z0-9.-]+\.[a-z.]+ ' "$R" 2>/dev/null || true)
  CM=$(grep -c 'cert-manager' "$R" 2>/dev/null || true)
  if [ "${NONCM:-0}" -gt "${CM:-0}" ]; then
    echo -e "  ${YELLOW}WARN${NC}  the file seems to contain non-cert-manager CRDs too - the task asked only for cert-manager's"
  fi
fi

# ---------------------------------------------------------------- subject
if [ ! -s "$S" ]; then
  fail "$S exists and is not empty"
else
  pass "$S exists and is not empty"
  if grep -qi 'subject' "$S"; then
    pass "it documents the 'subject' field"
  else
    fail "it documents the 'subject' field"
  fi
  if grep -qiE '(countries|organizations|organizationalUnits|localities|provinces|streetAddresses|postalCodes|serialNumber)' "$S"; then
    pass "it contains the subject sub-fields from kubectl explain"
  else
    fail "it contains the subject sub-fields from kubectl explain  ${YELLOW}expected things like organizations, countries, localities${NC}"
  fi
  if grep -qi 'error\|not found\|Unknown' "$S"; then
    fail "it is not an error message  ${YELLOW}check the content of $S${NC}"
  else
    pass "it is real documentation, not an error message"
  fi
fi

summary
