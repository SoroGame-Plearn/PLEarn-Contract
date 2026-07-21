#!/usr/bin/env bash
# run-tests.sh — PLEarn test runner
#
# Features:
#   • Progress bar with ETA
#   • Color-coded pass/fail/skip output
#   • Per-challenge execution timing
#   • Detailed failure reports (test names + snippets)
#   • JSON report at /tmp/plearnlogs/report-<timestamp>.json
#   • Per-challenge log artifacts under /tmp/plearnlogs/
#
# Usage:
#   ./scripts/run-tests.sh [--no-color] [--report-dir <dir>]

# ── strict mode ────────────────────────────────────────────────────────────────
set -euo pipefail

# ── option parsing ─────────────────────────────────────────────────────────────
COLOR=true
REPORT_DIR="/tmp/plearnlogs"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-color)   COLOR=false ; shift ;;
    --report-dir) REPORT_DIR="$2" ; shift 2 ;;
    -h|--help)
      echo "Usage: ./scripts/run-tests.sh [--no-color] [--report-dir <dir>]"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2 ; exit 1 ;;
  esac
done

# ── colour palette ─────────────────────────────────────────────────────────────
if $COLOR && [[ -t 1 ]]; then
  C_RESET='\033[0m'
  C_BOLD='\033[1m'
  C_DIM='\033[2m'
  C_GREEN='\033[0;32m'
  C_RED='\033[0;31m'
  C_YELLOW='\033[1;33m'
  C_CYAN='\033[0;36m'
  C_BLUE='\033[0;34m'
  C_MAGENTA='\033[0;35m'
  C_WHITE='\033[1;37m'
else
  C_RESET='' C_BOLD='' C_DIM='' C_GREEN='' C_RED=''
  C_YELLOW='' C_CYAN='' C_BLUE='' C_MAGENTA='' C_WHITE=''
fi

# ── helpers ────────────────────────────────────────────────────────────────────
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

timestamp_ms() {
  # milliseconds since epoch; fallback to seconds if %N unsupported
  date +%s%3N 2>/dev/null || date +%s
}

format_duration() {
  local ms=$1
  local s=$(( ms / 1000 ))
  local frac=$(( (ms % 1000) / 10 ))   # two decimal places
  printf "%d.%02ds" "$s" "$frac"
}

fmt_eta() {
  local remaining_s=$1
  if (( remaining_s < 60 )); then
    printf "%ds" "$remaining_s"
  else
    printf "%dm%ds" $(( remaining_s / 60 )) $(( remaining_s % 60 ))
  fi
}

# JSON-safe string escaping (no external deps)
json_escape() {
  local s="$1"
  # escape backslash, double-quote, tab, newline, carriage-return
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  echo "$s"
}

# Draw a progress bar: draw_progress <done> <total> <bar_width>
draw_progress() {
  local done=$1 total=$2 width=${3:-40}
  local pct=0
  (( total > 0 )) && pct=$(( done * 100 / total ))
  local filled=$(( done * width / (total > 0 ? total : 1) ))
  local empty=$(( width - filled ))
  local bar=""
  (( filled > 0 )) && bar+=$(printf '%0.s█' $(seq 1 $filled))
  (( empty  > 0 )) && bar+=$(printf '%0.s░' $(seq 1 $empty))
  printf "${C_CYAN}[%s]${C_RESET} ${C_BOLD}%3d%%${C_RESET} (%d/%d)" \
    "$bar" "$pct" "$done" "$total"
}

# ── discover challenges ────────────────────────────────────────────────────────
mapfile -t TOMLS < <(find "$ROOT/challenges" -name "Cargo.toml" | sort)
TOTAL=${#TOMLS[@]}

if (( TOTAL == 0 )); then
  echo -e "${C_YELLOW}⚠  No challenges found under challenges/.${C_RESET}"
  exit 0
fi

# ── prepare log directory ──────────────────────────────────────────────────────
mkdir -p "$REPORT_DIR"
RUN_TS=$(date +%Y%m%d_%H%M%S)
JSON_REPORT="$REPORT_DIR/report-${RUN_TS}.json"
JSON_LATEST="$REPORT_DIR/report-latest.json"

# ── header ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${C_BOLD}${C_WHITE}╔══════════════════════════════════════════════════════╗${C_RESET}"
echo -e "${C_BOLD}${C_WHITE}║          PLEarn — Test Runner                        ║${C_RESET}"
echo -e "${C_BOLD}${C_WHITE}╚══════════════════════════════════════════════════════╝${C_RESET}"
echo -e "${C_DIM}  Challenges found : ${TOTAL}${C_RESET}"
echo -e "${C_DIM}  Log directory    : ${REPORT_DIR}${C_RESET}"
echo -e "${C_DIM}  JSON report      : ${JSON_REPORT}${C_RESET}"
echo ""

# ── counters and accumulators ──────────────────────────────────────────────────
PASS=0
FAIL=0
SKIP=0
DONE=0
TOTAL_MS=0

SUITE_START_MS=$(timestamp_ms)

# JSON entries array (built up as a string for portability)
JSON_ENTRIES=""

# We'll collect failure details for the final summary
declare -a FAIL_NAMES=()
declare -a FAIL_SNIPPETS=()

# ── per-challenge loop ─────────────────────────────────────────────────────────
for toml in "${TOMLS[@]}"; do
  challenge_dir="$(dirname "$toml")"
  # Derive a short display name: difficulty/number-name
  rel_path="${challenge_dir#"$ROOT/challenges/"}"
  challenge_name="$(basename "$challenge_dir")"
  difficulty="$(echo "$rel_path" | cut -d'/' -f1)"

  # Per-challenge log file
  safe_name="${rel_path//\//_}"
  log_file="$REPORT_DIR/${safe_name}.log"

  DONE=$(( DONE + 1 ))

  # ── print current progress line ──────────────────────────────────────────
  echo -e -n "\r$(draw_progress $((DONE - 1)) $TOTAL)  ${C_DIM}Running ${rel_path}…${C_RESET}"

  # ── timing start ─────────────────────────────────────────────────────────
  t_start=$(timestamp_ms)

  # ── run cargo test ────────────────────────────────────────────────────────
  # Capture output; do NOT let the script abort on failure (|| true)
  raw_output=$(cargo test --manifest-path "$toml" 2>&1) || true
  exit_code=$?

  t_end=$(timestamp_ms)
  elapsed_ms=$(( t_end - t_start ))
  TOTAL_MS=$(( TOTAL_MS + elapsed_ms ))
  elapsed_fmt=$(format_duration "$elapsed_ms")

  # ── save log artifact ─────────────────────────────────────────────────────
  {
    echo "PLEarn test log"
    echo "Challenge : $rel_path"
    echo "Run at    : $(date)"
    echo "Exit code : $exit_code"
    echo "Duration  : $elapsed_fmt"
    echo "────────────────────────────────────────────────────────"
    echo "$raw_output"
  } > "$log_file"

  # ── parse individual test lines ───────────────────────────────────────────
  passed_tests=()
  failed_tests=()
  ignored_tests=()

  while IFS= read -r line; do
    if [[ "$line" =~ ^test[[:space:]]+([^[:space:]]+)[[:space:]]+\.\.\.[[:space:]]+ok$ ]]; then
      passed_tests+=("${BASH_REMATCH[1]}")
    elif [[ "$line" =~ ^test[[:space:]]+([^[:space:]]+)[[:space:]]+\.\.\.[[:space:]]+FAILED$ ]]; then
      failed_tests+=("${BASH_REMATCH[1]}")
    elif [[ "$line" =~ ^test[[:space:]]+([^[:space:]]+)[[:space:]]+\.\.\.[[:space:]]+ignored$ ]]; then
      ignored_tests+=("${BASH_REMATCH[1]}")
    fi
  done <<< "$raw_output"

  n_pass=${#passed_tests[@]}
  n_fail=${#failed_tests[@]}
  n_ignore=${#ignored_tests[@]}

  # ── status icon + counters ────────────────────────────────────────────────
  if (( exit_code == 0 )); then
    status="pass"
    PASS=$(( PASS + 1 ))
    icon="${C_GREEN}✅ PASS${C_RESET}"
  else
    status="fail"
    FAIL=$(( FAIL + 1 ))
    icon="${C_RED}❌ FAIL${C_RESET}"
  fi

  # Skip counter: challenges with no test cases at all
  if (( n_pass + n_fail + n_ignore == 0 )); then
    SKIP=$(( SKIP + 1 ))
    status="skip"
    icon="${C_YELLOW}⚠  SKIP${C_RESET}"
  fi

  # ── overwrite the in-progress line with the result ────────────────────────
  echo -e "\r$(draw_progress $DONE $TOTAL)  ${icon}  ${C_BOLD}${rel_path}${C_RESET} ${C_DIM}(${elapsed_fmt}, ${n_pass}✓ ${n_fail}✗ ${n_ignore}~)${C_RESET}    "

  # ── collect failure detail for final summary ──────────────────────────────
  if [[ "$status" == "fail" ]]; then
    FAIL_NAMES+=("$rel_path")
    # Extract the failure snippet from cargo output (lines between FAILURES: and the test result summary)
    snippet=$(echo "$raw_output" | awk '/^failures:/{p=1; next} /^test result:/{p=0} p' | head -30)
    FAIL_SNIPPETS+=("$snippet")
  fi

  # ── ETA update ────────────────────────────────────────────────────────────
  if (( DONE < TOTAL && TOTAL_MS > 0 )); then
    avg_ms=$(( TOTAL_MS / DONE ))
    remaining_s=$(( avg_ms * (TOTAL - DONE) / 1000 ))
    echo -e "   ${C_DIM}  ETA ≈ $(fmt_eta $remaining_s) remaining${C_RESET}"
  fi

  # ── build JSON entry for this challenge ───────────────────────────────────
  # Build JSON arrays for test names
  build_json_array() {
    local arr=("$@")
    local out="["
    local first=true
    for item in "${arr[@]}"; do
      $first || out+=","
      out+="\"$(json_escape "$item")\""
      first=false
    done
    out+="]"
    echo "$out"
  }

  passed_json=$(build_json_array "${passed_tests[@]+"${passed_tests[@]}"}")
  failed_json=$(build_json_array "${failed_tests[@]+"${failed_tests[@]}"}")
  ignored_json=$(build_json_array "${ignored_tests[@]+"${ignored_tests[@]}"}")

  entry="{
    \"challenge\": \"$(json_escape "$rel_path")\",
    \"difficulty\": \"$(json_escape "$difficulty")\",
    \"status\": \"$status\",
    \"exit_code\": $exit_code,
    \"duration_ms\": $elapsed_ms,
    \"duration_fmt\": \"$elapsed_fmt\",
    \"tests_passed\": $n_pass,
    \"tests_failed\": $n_fail,
    \"tests_ignored\": $n_ignore,
    \"passed_tests\": $passed_json,
    \"failed_tests\": $failed_json,
    \"ignored_tests\": $ignored_json,
    \"log_file\": \"$(json_escape "$log_file")\"
  }"

  if [[ -n "$JSON_ENTRIES" ]]; then
    JSON_ENTRIES+=",
$entry"
  else
    JSON_ENTRIES="$entry"
  fi

done

# ── final elapsed ──────────────────────────────────────────────────────────────
SUITE_END_MS=$(timestamp_ms)
SUITE_ELAPSED_MS=$(( SUITE_END_MS - SUITE_START_MS ))
SUITE_ELAPSED_FMT=$(format_duration "$SUITE_ELAPSED_MS")

# ── summary banner ─────────────────────────────────────────────────────────────
echo ""
echo -e "${C_BOLD}${C_WHITE}────────────────────────────────────────────────────────${C_RESET}"
echo -e "${C_BOLD}  Summary${C_RESET}"
echo -e "${C_BOLD}${C_WHITE}────────────────────────────────────────────────────────${C_RESET}"
echo ""
echo -e "  ${C_GREEN}${C_BOLD}Passed :${C_RESET}  ${C_GREEN}${PASS}${C_RESET}"
echo -e "  ${C_RED}${C_BOLD}Failed :${C_RESET}  ${C_RED}${FAIL}${C_RESET}"
echo -e "  ${C_YELLOW}${C_BOLD}Skipped:${C_RESET}  ${C_YELLOW}${SKIP}${C_RESET}"
echo -e "  ${C_BOLD}Total  :  ${TOTAL}${C_RESET}"
echo -e "  ${C_DIM}Time   :  ${SUITE_ELAPSED_FMT}${C_RESET}"
echo ""

# ── detailed failure reports ───────────────────────────────────────────────────
if (( ${#FAIL_NAMES[@]} > 0 )); then
  echo -e "${C_BOLD}${C_RED}────────────────────────────────────────────────────────${C_RESET}"
  echo -e "${C_BOLD}${C_RED}  Failure Details${C_RESET}"
  echo -e "${C_BOLD}${C_RED}────────────────────────────────────────────────────────${C_RESET}"
  for i in "${!FAIL_NAMES[@]}"; do
    echo ""
    echo -e "  ${C_RED}${C_BOLD}▶ ${FAIL_NAMES[$i]}${C_RESET}"
    echo -e "  ${C_DIM}────────────────────────────────────────${C_RESET}"
    if [[ -n "${FAIL_SNIPPETS[$i]}" ]]; then
      while IFS= read -r fline; do
        echo -e "  ${C_DIM}${fline}${C_RESET}"
      done <<< "${FAIL_SNIPPETS[$i]}"
    else
      echo -e "  ${C_DIM}(see log: $REPORT_DIR/${FAIL_NAMES[$i]//\//_}.log)${C_RESET}"
    fi
  done
  echo ""
fi

# ── JSON report ────────────────────────────────────────────────────────────────
OVERALL_STATUS="pass"
(( FAIL > 0 )) && OVERALL_STATUS="fail"

cat > "$JSON_REPORT" << JSONEOF
{
  "run_timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "overall_status": "$OVERALL_STATUS",
  "total_challenges": $TOTAL,
  "passed": $PASS,
  "failed": $FAIL,
  "skipped": $SKIP,
  "total_duration_ms": $SUITE_ELAPSED_MS,
  "total_duration_fmt": "$SUITE_ELAPSED_FMT",
  "report_dir": "$(json_escape "$REPORT_DIR")",
  "challenges": [
$JSON_ENTRIES
  ]
}
JSONEOF

# Symlink latest report
ln -sf "$JSON_REPORT" "$JSON_LATEST"

echo -e "  ${C_CYAN}📄 JSON report : ${JSON_REPORT}${C_RESET}"
echo -e "  ${C_CYAN}🔗 Latest link : ${JSON_LATEST}${C_RESET}"
echo -e "  ${C_CYAN}📁 Log dir     : ${REPORT_DIR}${C_RESET}"
echo ""

# ── final exit code ────────────────────────────────────────────────────────────
if (( FAIL > 0 )); then
  echo -e "${C_RED}${C_BOLD}  ✖ ${FAIL} challenge(s) failed.${C_RESET}"
  echo ""
  exit 1
else
  echo -e "${C_GREEN}${C_BOLD}  ✔ All challenges passed!${C_RESET}"
  echo ""
  exit 0
fi
