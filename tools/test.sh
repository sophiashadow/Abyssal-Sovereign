#!/usr/bin/env sh
# Headless test command. Usage: tools/test.sh [test_name]
# Uses $GODOT, else `godot` on PATH, else ./.tools/godot.
set -eu
cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT:-}"
if [ -z "$GODOT_BIN" ]; then
  if command -v godot >/dev/null 2>&1; then GODOT_BIN=godot
  elif [ -x ./.tools/godot ]; then GODOT_BIN=./.tools/godot
  else echo "Godot 4.7 not found: set GODOT=/path/to/godot" >&2; exit 2; fi
fi
mkdir -p test-results
# Build the class cache on a fresh clone (no editor needed).
"$GODOT_BIN" --headless --path . --import >/dev/null 2>&1 || true
ONLY=""
[ $# -gt 0 ] && ONLY="--only=$1"
set +e
"$GODOT_BIN" --headless --path . --script res://tests/run_tests.gd -- $ONLY > test-results/last.log 2>&1
STATUS=$?
cat test-results/last.log
set -e
# GDScript runtime errors abort a test function without failing an assertion;
# treat any engine error in the log as a failure.
if grep -E "SCRIPT ERROR|^ERROR:|Parse Error" test-results/last.log >/dev/null; then
  echo "ENGINE ERRORS DETECTED (see test-results/last.log): failing the run." >&2
  exit 1
fi
exit $STATUS
