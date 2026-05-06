#!/bin/bash
# validate.sh — Validate a single challenge
# Usage: ./scripts/validate.sh challenges/beginner/01-hello-token

set -e

CHALLENGE_PATH="$1"

if [ -z "$CHALLENGE_PATH" ]; then
  echo "Usage: ./scripts/validate.sh <path-to-challenge>"
  echo "Example: ./scripts/validate.sh challenges/beginner/01-hello-token"
  exit 1
fi

if [ ! -f "$CHALLENGE_PATH/Cargo.toml" ]; then
  echo "❌ No Cargo.toml found in $CHALLENGE_PATH"
  exit 1
fi

echo "🔍 Validating: $CHALLENGE_PATH"
cargo test --manifest-path "$CHALLENGE_PATH/Cargo.toml"

echo "✅ Challenge passed!"
