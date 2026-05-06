#!/bin/bash
# run-tests.sh — Run all challenge tests

set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

for toml in "$ROOT"/challenges/*/*/Cargo.toml; do
  challenge=$(dirname "$toml")
  echo "🧪 Testing: $challenge"
  if cargo test --manifest-path "$toml" 2>&1; then
    echo "✅ PASSED: $(basename "$challenge")"
    ((PASS++))
  else
    echo "❌ FAILED: $(basename "$challenge")"
    ((FAIL++))
  fi
  echo "---"
done

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
