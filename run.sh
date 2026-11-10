#!/usr/bin/env bash
# ./run.sh 1        prepare the cluster for question 1 and show the task
# ./run.sh list     show all questions
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOLD='\033[1m'; NC='\033[0m'

qdir() {
  local n; n=$(printf '%02d' "$1" 2>/dev/null) || return 1
  local d; d=$(find "$ROOT/questions" -maxdepth 1 -type d -name "${n}-*" | head -1)
  [ -n "$d" ] && printf '%s' "$d"
}

if [ $# -eq 0 ] || [ "${1:-}" = "list" ]; then
  echo -e "${BOLD}Questions${NC}"
  for d in "$ROOT"/questions/*/; do
    b=$(basename "$d")
    printf '  %-4s %s\n' "${b%%-*}" "$(echo "${b#*-}" | tr '-' ' ')"
  done
  echo
  echo "  ./run.sh <n>      start a question"
  echo "  ./check.sh <n>    check your answer"
  echo "  ./cleanup.sh <n>  remove what the question created"
  exit 0
fi

D=$(qdir "$1") || { echo "No question $1"; exit 1; }
[ -n "$D" ] || { echo "No question $1"; exit 1; }

bash "$D/setup.sh" || { echo "setup failed"; exit 1; }
echo
echo "----------------------------------------------------------------"
cat "$D/question.md"
echo "----------------------------------------------------------------"
echo
echo "  check your answer:  ./check.sh $1"
echo "  solution:           cat $D/solution.md"
