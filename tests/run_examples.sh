#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "Building..."
make

echo "Running good example (should succeed)..."
./tasklang < examples/input.txt

echo "Running error examples (should fail)..."
for f in examples/error_*.txt examples/invalid_*.txt; do
  echo "-> Testing $f"
  if ./tasklang < "$f" >/dev/null 2>&1; then
    echo "Expected failure for $f but it succeeded"
    exit 2
  fi
done

echo "All example tests behaved as expected"
