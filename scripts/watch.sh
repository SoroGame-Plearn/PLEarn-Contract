#!/bin/bash
# watch.sh — Watch mode: rerun challenge validation on any file change
# Usage: ./scripts/watch.sh <path-to-challenge> [--html]
#
# Watches src/ and tests/ inside the challenge directory.
# Requires: inotifywait (inotify-tools) or falls back to a polling loop.

# ── colours ───────────────────────────────────────────────────────────────────
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ── argument parsing ──────────────────────────────────────────────────────────
CHALLENGE_PATH=""
EXTRA_FLAGS=""

for arg in "$@"; do
  case "$arg" in
    --html) EXTRA_FLAGS="$EXTRA_FLAGS --html" ;;
    *) CHALLENGE_PATH="$arg" ;;
  esac
done

if [ -z "$CHALLENGE_PATH" ]; then
  echo -e "${YELLOW}Usage:${RESET} ./scripts/watch.sh <path-to-challenge> [--html]"
  echo -e "  Example: ./scripts/watch.sh challenges/beginner/01-hello-token"
  exit 1
fi

if [ ! -f "$CHALLENGE_PATH/Cargo.toml" ]; then
  echo -e "\033[0;31m❌  No Cargo.toml found in: $CHALLENGE_PATH\033[0m"
  exit 1
fi

# ── resolve paths ─────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VALIDATOR="$SCRIPT_DIR/feedback_validator.sh"

if [ ! -x "$VALIDATOR" ]; then
  echo -e "\033[0;31m❌  feedback_validator.sh not found or not executable at: $VALIDATOR\033[0m"
  exit 1
fi

WATCH_DIRS=()
for d in src tests; do
  [ -d "$CHALLENGE_PATH/$d" ] && WATCH_DIRS+=("$CHALLENGE_PATH/$d")
done
[ ${#WATCH_DIRS[@]} -eq 0 ] && WATCH_DIRS=("$CHALLENGE_PATH")

# ── run once immediately ──────────────────────────────────────────────────────
clear
"$VALIDATOR" $CHALLENGE_PATH $EXTRA_FLAGS

# ── watch loop ────────────────────────────────────────────────────────────────
if command -v inotifywait &>/dev/null; then
  # ── inotify path (Linux) ──────────────────────────────────────────────────
  echo ""
  echo -e "${CYAN}${BOLD}👁  Watching for changes (inotify)…  Press Ctrl-C to stop.${RESET}"
  echo -e "${DIM}  Watching: ${WATCH_DIRS[*]}${RESET}"
  echo ""

  while inotifywait -r -e modify,create,delete,move \
        --include '\.(rs|toml)$' \
        "${WATCH_DIRS[@]}" 2>/dev/null; do
    echo ""
    echo -e "${CYAN}${BOLD}🔄  Change detected — rerunning validator…${RESET}"
    echo ""
    sleep 0.3   # brief debounce
    clear
    "$VALIDATOR" $CHALLENGE_PATH $EXTRA_FLAGS
    echo ""
    echo -e "${CYAN}${BOLD}👁  Watching for changes…  Press Ctrl-C to stop.${RESET}"
    echo -e "${DIM}  Watching: ${WATCH_DIRS[*]}${RESET}"
    echo ""
  done

elif command -v fswatch &>/dev/null; then
  # ── fswatch path (macOS / optional) ──────────────────────────────────────
  echo ""
  echo -e "${CYAN}${BOLD}👁  Watching for changes (fswatch)…  Press Ctrl-C to stop.${RESET}"
  echo -e "${DIM}  Watching: ${WATCH_DIRS[*]}${RESET}"
  echo ""

  fswatch -r --include='.*\.(rs|toml)$' --exclude='.*' "${WATCH_DIRS[@]}" | \
  while read -r _event; do
    echo ""
    echo -e "${CYAN}${BOLD}🔄  Change detected — rerunning validator…${RESET}"
    echo ""
    sleep 0.3
    clear
    "$VALIDATOR" $CHALLENGE_PATH $EXTRA_FLAGS
    echo ""
    echo -e "${CYAN}${BOLD}👁  Watching for changes…  Press Ctrl-C to stop.${RESET}"
    echo -e "${DIM}  Watching: ${WATCH_DIRS[*]}${RESET}"
    echo ""
  done

else
  # ── polling fallback (no inotify/fswatch available) ───────────────────────
  echo ""
  echo -e "${YELLOW}⚠  inotifywait / fswatch not found — using 2-second polling loop.${RESET}"
  echo -e "${DIM}  Install inotify-tools for instant detection: apt install inotify-tools${RESET}"
  echo ""
  echo -e "${CYAN}${BOLD}👁  Watching for changes (polling)…  Press Ctrl-C to stop.${RESET}"
  echo -e "${DIM}  Watching: ${WATCH_DIRS[*]}${RESET}"
  echo ""

  # Build initial checksum of all .rs and .toml files
  get_checksum() {
    find "${WATCH_DIRS[@]}" -name '*.rs' -o -name '*.toml' 2>/dev/null \
      | sort | xargs md5sum 2>/dev/null | md5sum
  }

  LAST_SUM=$(get_checksum)

  while true; do
    sleep 2
    CURRENT_SUM=$(get_checksum)
    if [ "$CURRENT_SUM" != "$LAST_SUM" ]; then
      LAST_SUM="$CURRENT_SUM"
      echo ""
      echo -e "${CYAN}${BOLD}🔄  Change detected — rerunning validator…${RESET}"
      echo ""
      sleep 0.2
      clear
      "$VALIDATOR" $CHALLENGE_PATH $EXTRA_FLAGS
      echo ""
      echo -e "${CYAN}${BOLD}👁  Watching for changes (polling)…  Press Ctrl-C to stop.${RESET}"
      echo -e "${DIM}  Watching: ${WATCH_DIRS[*]}${RESET}"
      echo ""
    fi
  done
fi
