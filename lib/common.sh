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
