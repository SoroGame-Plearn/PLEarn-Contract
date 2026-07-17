#!/bin/bash
# feedback_validator.sh — Enhanced challenge validator with detailed feedback
# Usage: ./scripts/feedback_validator.sh <path-to-challenge> [--html]
#
# Parses cargo test output to show:
#   - Which test cases passed vs failed
#   - Assertion messages from failed tests
#   - Next-step suggestions based on failure patterns
#   - Optional HTML report (--html flag)

# ── colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ── helpers ───────────────────────────────────────────────────────────────────
print_header() {
  echo ""
  echo -e "${BOLD}╔══════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}║          PLEarn — Challenge Feedback Validator           ║${RESET}"
  echo -e "${BOLD}╚══════════════════════════════════════════════════════════╝${RESET}"
  echo ""
}

print_section() {
  echo -e "${CYAN}${BOLD}── $1 ──────────────────────────────────────────────────${RESET}"
}

# ── argument parsing ──────────────────────────────────────────────────────────
CHALLENGE_PATH=""
GEN_HTML=false

for arg in "$@"; do
  case "$arg" in
    --html) GEN_HTML=true ;;
    *) CHALLENGE_PATH="$arg" ;;
  esac
done

if [ -z "$CHALLENGE_PATH" ]; then
  echo -e "${RED}Usage:${RESET} ./scripts/feedback_validator.sh <path-to-challenge> [--html]"
  echo -e "  Example: ./scripts/feedback_validator.sh challenges/beginner/01-hello-token"
  exit 1
fi

if [ ! -f "$CHALLENGE_PATH/Cargo.toml" ]; then
  echo -e "${RED}❌  No Cargo.toml found in: $CHALLENGE_PATH${RESET}"
  exit 1
fi

# ── read metadata from INSTRUCTIONS.md ───────────────────────────────────────
INSTRUCTIONS="$CHALLENGE_PATH/INSTRUCTIONS.md"
DIFFICULTY=""
TIME_ESTIMATE=""
CHALLENGE_TITLE=""

if [ -f "$INSTRUCTIONS" ]; then
  DIFFICULTY=$(grep -i "^## Difficulty" "$INSTRUCTIONS" | head -1 | sed 's/## Difficulty:[[:space:]]*//' | sed 's/## Difficulty[[:space:]]*//')
  TIME_ESTIMATE=$(grep -i "^## Time Estimate" "$INSTRUCTIONS" | head -1 | sed 's/## Time Estimate:[[:space:]]*//' | sed 's/## Time Estimate[[:space:]]*//')
  CHALLENGE_TITLE=$(grep -i "^# Challenge" "$INSTRUCTIONS" | head -1 | sed 's/# Challenge:[[:space:]]*//' | sed 's/# Challenge[[:space:]]*//')
fi

[ -z "$CHALLENGE_TITLE" ] && CHALLENGE_TITLE="$(basename "$CHALLENGE_PATH")"
[ -z "$DIFFICULTY" ]      && DIFFICULTY="Unknown"
[ -z "$TIME_ESTIMATE" ]   && TIME_ESTIMATE="–"

# ── difficulty badge ──────────────────────────────────────────────────────────
difficulty_badge() {
  case "$(echo "$1" | tr '[:upper:]' '[:lower:]')" in
    beginner)     echo -e "${GREEN}🟢 Beginner${RESET}" ;;
    intermediate) echo -e "${YELLOW}🟡 Intermediate${RESET}" ;;
    advanced)     echo -e "${RED}🔴 Advanced${RESET}" ;;
    *)            echo -e "${DIM}⚪ $1${RESET}" ;;
  esac
}

# ── run tests and capture output ──────────────────────────────────────────────
print_header

print_section "Challenge Info"
echo -e "  ${BOLD}Challenge:${RESET}      $CHALLENGE_TITLE"
echo -e "  ${BOLD}Difficulty:${RESET}     $(difficulty_badge "$DIFFICULTY")"
echo -e "  ${BOLD}Time Estimate:${RESET}  $TIME_ESTIMATE"
echo -e "  ${BOLD}Path:${RESET}           $CHALLENGE_PATH"
echo ""

print_section "Running Tests"
echo -e "  ${DIM}cargo test --manifest-path $CHALLENGE_PATH/Cargo.toml${RESET}"
echo ""

# Capture both stdout and stderr; cargo test writes to stderr
RAW_OUTPUT=$(cargo test --manifest-path "$CHALLENGE_PATH/Cargo.toml" 2>&1)
EXIT_CODE=$?

# ── parse test results ────────────────────────────────────────────────────────
# Lines like:  "test test_name ... ok"  or  "test test_name ... FAILED"
PASSED_TESTS=()
FAILED_TESTS=()

while IFS= read -r line; do
  if [[ "$line" =~ ^test[[:space:]]+([^[:space:]]+)[[:space:]]+\.\.\.[[:space:]]+ok$ ]]; then
    PASSED_TESTS+=("${BASH_REMATCH[1]}")
  elif [[ "$line" =~ ^test[[:space:]]+([^[:space:]]+)[[:space:]]+\.\.\.[[:space:]]+FAILED$ ]]; then
    FAILED_TESTS+=("${BASH_REMATCH[1]}")
  fi
done <<< "$RAW_OUTPUT"

TOTAL_PASS=${#PASSED_TESTS[@]}
TOTAL_FAIL=${#FAILED_TESTS[@]}
TOTAL=$((TOTAL_PASS + TOTAL_FAIL))

# ── print per-test results ────────────────────────────────────────────────────
print_section "Test Results"

if [ "$TOTAL" -eq 0 ]; then
  echo -e "  ${YELLOW}⚠  No test cases detected. Check that tests compile correctly.${RESET}"
else
  for t in "${PASSED_TESTS[@]}"; do
    echo -e "  ${GREEN}✅  PASS${RESET}  $t"
  done
  for t in "${FAILED_TESTS[@]}"; do
    echo -e "  ${RED}❌  FAIL${RESET}  $t"
  done
fi

echo ""
echo -e "  ${BOLD}Score: $TOTAL_PASS / $TOTAL passed${RESET}"
echo ""

# ── extract failure details ───────────────────────────────────────────────────
if [ "$TOTAL_FAIL" -gt 0 ]; then
  print_section "Failure Details"

  # Collect the "failures:" block from cargo test output
  IN_FAILURES=false
  CURRENT_TEST=""
  declare -A FAILURE_BODY

  while IFS= read -r line; do
    if [[ "$line" =~ ^failures:$ ]]; then
      IN_FAILURES=true
      continue
    fi

    if $IN_FAILURES; then
      # New test block header: "---- test_name stdout ----"
      if [[ "$line" =~ ^----[[:space:]]+([^[:space:]]+)[[:space:]]+stdout[[:space:]]+----$ ]]; then
        CURRENT_TEST="${BASH_REMATCH[1]}"
        FAILURE_BODY["$CURRENT_TEST"]=""
        continue
      fi

      # End of failures section
      if [[ "$line" =~ ^failures:$ ]] || [[ "$line" =~ ^test[[:space:]]+result ]]; then
        IN_FAILURES=false
        continue
      fi

      # Append to current test body
      if [ -n "$CURRENT_TEST" ] && [ -n "$line" ]; then
        FAILURE_BODY["$CURRENT_TEST"]+="$line"$'\n'
      fi
    fi
  done <<< "$RAW_OUTPUT"

  for t in "${FAILED_TESTS[@]}"; do
    echo ""
    echo -e "  ${RED}${BOLD}▶ $t${RESET}"
    body="${FAILURE_BODY[$t]}"
    if [ -n "$body" ]; then
      while IFS= read -r bline; do
        echo -e "    ${DIM}$bline${RESET}"
      done <<< "$body"
    else
      # fallback: grep for the test name in raw output
      grep -A 10 "---- $t stdout ----" <<< "$RAW_OUTPUT" | tail -n +2 | head -10 | \
        while IFS= read -r bline; do echo -e "    ${DIM}$bline${RESET}"; done
    fi
  done
  echo ""
fi

# ── next-step suggestions based on failure patterns ───────────────────────────
if [ "$TOTAL_FAIL" -gt 0 ] || [ "$EXIT_CODE" -ne 0 ]; then
  print_section "Suggestions"

  # Pattern-based hints
  if echo "$RAW_OUTPUT" | grep -q "cannot find function\|unresolved import\|not found in this scope"; then
    echo -e "  ${YELLOW}💡  Missing function or import — check that all required functions are implemented in src/lib.rs${RESET}"
  fi

  if echo "$RAW_OUTPUT" | grep -q "TODO\|unimplemented!\|todo!"; then
    echo -e "  ${YELLOW}💡  Found unimplemented stubs — fill in all TODO blocks in src/lib.rs${RESET}"
  fi

  if echo "$RAW_OUTPUT" | grep -q "panicked at\|called \`Option::unwrap()\`\|called \`Result::unwrap()\`"; then
    echo -e "  ${YELLOW}💡  A panic occurred — check your error handling and guard clauses (insufficient funds, invalid inputs, etc.)${RESET}"
  fi

  if echo "$RAW_OUTPUT" | grep -q "assertion.*failed\|assert_eq.*left.*right\|left ==\|right =="; then
    echo -e "  ${YELLOW}💡  Assertion mismatch — a returned value doesn't match the expected value. Re-read the Expected Behavior section in INSTRUCTIONS.md${RESET}"
  fi

  if echo "$RAW_OUTPUT" | grep -q "require_auth\|auth.*failed\|Unauthorized\|HostError"; then
    echo -e "  ${YELLOW}💡  Authorization error — make sure you call Address::require_auth() where required${RESET}"
  fi

  if echo "$RAW_OUTPUT" | grep -q "error\[E[0-9]\+\]\|^error:"; then
    echo -e "  ${YELLOW}💡  Compile error — fix the Rust compilation errors above before tests can run${RESET}"
  fi

  # Generic fallback
  echo -e "  ${YELLOW}💡  Read INSTRUCTIONS.md carefully, especially the 'Expected Behavior' and 'Hints' sections${RESET}"
  echo -e "  ${YELLOW}💡  Run with RUST_BACKTRACE=1 for a full stack trace:${RESET}"
  echo -e "      ${DIM}RUST_BACKTRACE=1 cargo test --manifest-path $CHALLENGE_PATH/Cargo.toml${RESET}"
  echo ""
fi

# ── summary banner ────────────────────────────────────────────────────────────
echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
  echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════╗${RESET}"
  echo -e "${GREEN}${BOLD}║   🎉  Challenge Passed! All tests are green. ║${RESET}"
  echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════╝${RESET}"
else
  echo -e "${RED}${BOLD}╔══════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${RED}${BOLD}║   ❌  Challenge not yet solved. Keep going — you got this! ║${RESET}"
  echo -e "${RED}${BOLD}╚══════════════════════════════════════════════════════════╝${RESET}"
fi
echo ""

# ── optional HTML report ──────────────────────────────────────────────────────
if $GEN_HTML; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  HTML_SCRIPT="$SCRIPT_DIR/html_report.sh"
  if [ -x "$HTML_SCRIPT" ]; then
    "$HTML_SCRIPT" "$CHALLENGE_PATH"
  else
    echo -e "${YELLOW}⚠  html_report.sh not found or not executable. Skipping HTML report.${RESET}"
  fi
fi

exit "$EXIT_CODE"
