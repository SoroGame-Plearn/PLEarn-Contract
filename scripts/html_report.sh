#!/bin/bash
# html_report.sh — Generate an HTML test report for a challenge
# Usage: ./scripts/html_report.sh <path-to-challenge>
# Output: <challenge-path>/test-report.html

# ── argument parsing ──────────────────────────────────────────────────────────
CHALLENGE_PATH="$1"

if [ -z "$CHALLENGE_PATH" ]; then
  echo "Usage: ./scripts/html_report.sh <path-to-challenge>"
  echo "  Example: ./scripts/html_report.sh challenges/beginner/01-hello-token"
  exit 1
fi

if [ ! -f "$CHALLENGE_PATH/Cargo.toml" ]; then
  echo "❌  No Cargo.toml found in: $CHALLENGE_PATH"
  exit 1
fi

# ── read metadata ─────────────────────────────────────────────────────────────
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

# ── run tests ─────────────────────────────────────────────────────────────────
echo "🔍  Running tests for HTML report…"
RAW_OUTPUT=$(cargo test --manifest-path "$CHALLENGE_PATH/Cargo.toml" 2>&1)
EXIT_CODE=$?

# ── parse results ─────────────────────────────────────────────────────────────
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
[ "$TOTAL" -gt 0 ] && PERCENT=$(( TOTAL_PASS * 100 / TOTAL )) || PERCENT=0

# ── difficulty colour ─────────────────────────────────────────────────────────
case "$(echo "$DIFFICULTY" | tr '[:upper:]' '[:lower:]')" in
  beginner)     DIFF_COLOR="#22c55e"; DIFF_EMOJI="🟢" ;;
  intermediate) DIFF_COLOR="#f59e0b"; DIFF_EMOJI="🟡" ;;
  advanced)     DIFF_COLOR="#ef4444"; DIFF_EMOJI="🔴" ;;
  *)            DIFF_COLOR="#6b7280"; DIFF_EMOJI="⚪" ;;
esac

# ── escape HTML ───────────────────────────────────────────────────────────────
html_escape() {
  echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'
}

RAW_ESCAPED=$(html_escape "$RAW_OUTPUT")
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S %Z")
REPORT_FILE="$CHALLENGE_PATH/test-report.html"

# ── overall status ────────────────────────────────────────────────────────────
if [ "$EXIT_CODE" -eq 0 ]; then
  STATUS_LABEL="ALL TESTS PASSED"
  STATUS_COLOR="#22c55e"
  STATUS_BG="#f0fdf4"
  STATUS_EMOJI="🎉"
else
  STATUS_LABEL="TESTS FAILED"
  STATUS_COLOR="#ef4444"
  STATUS_BG="#fef2f2"
  STATUS_EMOJI="❌"
fi

# ── build test rows ───────────────────────────────────────────────────────────
TEST_ROWS=""
for t in "${PASSED_TESTS[@]}"; do
  TEST_ROWS+="<tr><td class=\"test-name\">$(html_escape "$t")</td><td class=\"badge pass\">PASS ✅</td></tr>"
done
for t in "${FAILED_TESTS[@]}"; do
  TEST_ROWS+="<tr><td class=\"test-name\">$(html_escape "$t")</td><td class=\"badge fail\">FAIL ❌</td></tr>"
done

# ── write HTML ────────────────────────────────────────────────────────────────
cat > "$REPORT_FILE" << HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>PLEarn — Test Report: ${CHALLENGE_TITLE}</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: #f8fafc;
      color: #1e293b;
      padding: 2rem;
      line-height: 1.6;
    }
    .container { max-width: 860px; margin: 0 auto; }

    /* header */
    header {
      background: linear-gradient(135deg, #1e3a5f 0%, #2563eb 100%);
      color: white;
      border-radius: 12px;
      padding: 2rem 2.5rem;
      margin-bottom: 2rem;
    }
    header h1 { font-size: 1.6rem; font-weight: 700; letter-spacing: -0.02em; }
    header .subtitle { opacity: 0.8; margin-top: 0.25rem; font-size: 0.95rem; }

    /* meta grid */
    .meta-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
      gap: 1rem;
      margin-bottom: 1.5rem;
    }
    .meta-card {
      background: white;
      border: 1px solid #e2e8f0;
      border-radius: 10px;
      padding: 1rem 1.25rem;
    }
    .meta-card .label { font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.05em; color: #64748b; }
    .meta-card .value { font-size: 1.1rem; font-weight: 600; margin-top: 0.2rem; }

    /* status banner */
    .status-banner {
      background: ${STATUS_BG};
      border: 2px solid ${STATUS_COLOR};
      border-radius: 10px;
      padding: 1.25rem 1.5rem;
      margin-bottom: 1.5rem;
      display: flex;
      align-items: center;
      gap: 0.75rem;
    }
    .status-banner .emoji { font-size: 1.8rem; }
    .status-banner .text h2 { color: ${STATUS_COLOR}; font-size: 1.15rem; font-weight: 700; }
    .status-banner .text p { color: #475569; font-size: 0.9rem; margin-top: 0.15rem; }

    /* progress bar */
    .progress-wrap { margin-bottom: 1.5rem; }
    .progress-label { display: flex; justify-content: space-between; margin-bottom: 0.4rem; font-size: 0.9rem; color: #475569; }
    .progress-bar { height: 12px; background: #e2e8f0; border-radius: 999px; overflow: hidden; }
    .progress-fill { height: 100%; border-radius: 999px; background: ${STATUS_COLOR}; width: ${PERCENT}%; transition: width 0.6s; }

    /* test table */
    .section-title {
      font-size: 1rem; font-weight: 600; color: #1e293b;
      margin-bottom: 0.75rem; padding-bottom: 0.4rem;
      border-bottom: 2px solid #e2e8f0;
    }
    table { width: 100%; border-collapse: collapse; background: white; border-radius: 10px; overflow: hidden; border: 1px solid #e2e8f0; margin-bottom: 1.5rem; }
    th { background: #f1f5f9; padding: 0.75rem 1rem; text-align: left; font-size: 0.8rem; text-transform: uppercase; letter-spacing: 0.05em; color: #64748b; }
    td { padding: 0.7rem 1rem; border-top: 1px solid #f1f5f9; font-size: 0.9rem; }
    tr:hover td { background: #f8fafc; }
    .test-name { font-family: 'Courier New', monospace; color: #334155; }
    .badge { font-weight: 600; font-size: 0.8rem; white-space: nowrap; }
    .badge.pass { color: #16a34a; }
    .badge.fail { color: #dc2626; }

    /* raw log */
    .log-toggle { cursor: pointer; user-select: none; font-size: 0.85rem; color: #2563eb; margin-bottom: 0.5rem; display: inline-block; }
    pre {
      background: #0f172a;
      color: #94a3b8;
      border-radius: 10px;
      padding: 1.25rem;
      font-size: 0.78rem;
      overflow-x: auto;
      white-space: pre-wrap;
      word-break: break-word;
      max-height: 420px;
      overflow-y: auto;
    }

    /* footer */
    footer { text-align: center; color: #94a3b8; font-size: 0.8rem; margin-top: 2rem; }
  </style>
</head>
<body>
<div class="container">

  <header>
    <h1>PLEarn — Test Report</h1>
    <div class="subtitle">${CHALLENGE_TITLE}</div>
  </header>

  <div class="meta-grid">
    <div class="meta-card">
      <div class="label">Difficulty</div>
      <div class="value" style="color:${DIFF_COLOR}">${DIFF_EMOJI} ${DIFFICULTY}</div>
    </div>
    <div class="meta-card">
      <div class="label">Time Estimate</div>
      <div class="value">${TIME_ESTIMATE}</div>
    </div>
    <div class="meta-card">
      <div class="label">Tests Passed</div>
      <div class="value">${TOTAL_PASS} / ${TOTAL}</div>
    </div>
    <div class="meta-card">
      <div class="label">Generated</div>
      <div class="value" style="font-size:0.85rem;">${TIMESTAMP}</div>
    </div>
  </div>

  <div class="status-banner">
    <div class="emoji">${STATUS_EMOJI}</div>
    <div class="text">
      <h2>${STATUS_LABEL}</h2>
      <p>${TOTAL_PASS} of ${TOTAL} tests passed (${PERCENT}%)</p>
    </div>
  </div>

  <div class="progress-wrap">
    <div class="progress-label">
      <span>Progress</span>
      <span>${PERCENT}%</span>
    </div>
    <div class="progress-bar">
      <div class="progress-fill"></div>
    </div>
  </div>

  <div class="section-title">Test Cases</div>
  <table>
    <thead><tr><th>Test Name</th><th>Result</th></tr></thead>
    <tbody>
      ${TEST_ROWS}
    </tbody>
  </table>

  <div class="section-title">Raw Output</div>
  <span class="log-toggle" onclick="document.getElementById('log').style.display=document.getElementById('log').style.display==='none'?'block':'none'">▶ Toggle full log</span>
  <pre id="log" style="display:none">${RAW_ESCAPED}</pre>

  <footer>
    Generated by PLEarn feedback_validator · ${TIMESTAMP}
  </footer>

</div>
</body>
</html>
HTML

echo "✅  HTML report written to: $REPORT_FILE"
exit "$EXIT_CODE"
