#!/usr/bin/env bash
# Shared helpers for validate scripts

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; BOLD='\033[1m'; NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0

pass() { echo -e "  ${GREEN}PASS${NC}  $1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { echo -e "  ${RED}FAIL${NC}  $1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

# check "what is being checked" "expected" "actual"
check() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    pass "$desc"
  else
    fail "$desc  ${YELLOW}expected:${NC} $expected  ${YELLOW}got:${NC} ${actual:-<empty>}"
  fi
}

# check_exists "what is being checked" <command...>
check_exists() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then pass "$desc"; else fail "$desc  (not found)"; fi
}

summary() {
  local total=$((PASS_COUNT + FAIL_COUNT))
  echo
  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}ALL CHECKS PASSED${NC}  ($PASS_COUNT/$total)"
    return 0
  else
    echo -e "${RED}${BOLD}$FAIL_COUNT of $total CHECKS FAILED${NC}"
    return 1
  fi
}

# field "$REPORT" key   -> prints the value of key=... from a key=value report.
# Used instead of eval so that answers containing $ " ' or ` cannot be executed.
field() {
  printf '%s\n' "$1" | sed -n "s/^$2=//p" | head -1
}

# Where setup scripts record baseline state that validate scripts compare against.
# Kept outside the repo so it never shows up in git status.
STATE_DIR="${HOME}/.cka-prep-state"
mkdir -p "$STATE_DIR" 2>/dev/null || true

# The validate scripts parse JSON with python3. Fail loudly rather than cryptically.
require_python() {
  if ! command -v python3 >/dev/null 2>&1; then
    echo -e "  ${RED}ERROR${NC}  python3 is not installed, so this check cannot run."
    echo "         Install it with:  apt-get update && apt-get install -y python3"
    exit 2
  fi
}
