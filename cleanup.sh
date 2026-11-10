#!/usr/bin/env bash
# ./cleanup.sh 1    remove what question 1 created
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
n=$(printf '%02d' "${1:-0}" 2>/dev/null)
D=$(find "$ROOT/questions" -maxdepth 1 -type d -name "${n}-*" | head -1)
[ -n "$D" ] || { echo "No question ${1:-}"; exit 1; }
bash "$D/cleanup.sh"
