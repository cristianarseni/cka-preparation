#!/usr/bin/env bash
# ./check.sh 1      check question 1
# ./check.sh all    check every question
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "${1:-}" = "all" ]; then
  rc=0
  for d in "$ROOT"/questions/*/; do
    bash "$d/validate.sh" || rc=1
    echo
  done
  exit $rc
fi

n=$(printf '%02d' "${1:-0}" 2>/dev/null)
D=$(find "$ROOT/questions" -maxdepth 1 -type d -name "${n}-*" | head -1)
[ -n "$D" ] || { echo "No question ${1:-}"; exit 1; }
bash "$D/validate.sh"
