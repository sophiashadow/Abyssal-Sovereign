#!/usr/bin/env sh
# Local regression gate (offline, zero cloud dependencies).
# Usage: tools/verify.sh [--soak] [--exports]
set -eu
cd "$(dirname "$0")/.."

GODOT_BIN="${GODOT:-}"
if [ -z "$GODOT_BIN" ]; then
  if command -v godot >/dev/null 2>&1; then GODOT_BIN=godot
  elif [ -x ./.tools/godot ]; then GODOT_BIN=./.tools/godot
  else echo "Godot 4.7 not found: set GODOT=/path/to/godot" >&2; exit 2; fi
fi

RUN_SOAK=0
RUN_EXPORTS=0
for arg in "$@"; do
  case "$arg" in
    --soak) RUN_SOAK=1 ;;
    --exports) RUN_EXPORTS=1 ;;
    *) echo "Unknown option: $arg (expected --soak, --exports)" >&2; exit 2 ;;
  esac
done

echo "==> 1. Headless test suite"
./tools/test.sh

echo "==> 2. UI smoke (1280x720 and 2340x1080)"
DISPLAY_WRAPPER=""
if [ -z "${DISPLAY:-}" ]; then
  if command -v xvfb-run >/dev/null 2>&1; then
    DISPLAY_WRAPPER="xvfb-run -a"
  else
    echo "No DISPLAY and xvfb-run not found; skipping UI smoke." >&2
    exit 2
  fi
fi

mkdir -p test-results
touch test-results/.gdignore
for res in 1280x720 2340x1080; do
  LOG="test-results/smoke_${res}.log"
  $DISPLAY_WRAPPER "$GODOT_BIN" --path . --resolution "$res" --audio-driver Dummy --script res://tools/ui_smoke.gd > "$LOG" 2>&1
  cat "$LOG"
  if grep -E "FAIL |SCRIPT ERROR|^ERROR:|Parse Error" "$LOG" >/dev/null; then
    echo "UI smoke errors detected at $res (see $LOG)." >&2
    exit 1
  fi
done

if [ "$RUN_SOAK" -eq 1 ]; then
  echo "==> 3. Held-out balance soak (180 runs)"
  "$GODOT_BIN" --headless --path . --script res://tools/soak.gd -- --seeds=20 --salt=heldout
fi

if [ "$RUN_EXPORTS" -eq 1 ]; then
  echo "==> 4. Platform exports & smoke verification"
  ./tools/export.sh all
  LINUX_LOG="test-results/linux_export_smoke.log"
  $DISPLAY_WRAPPER ./build/linux/abyssal-sovereign.x86_64 --audio-driver Dummy --quit-after 30 > "$LINUX_LOG" 2>&1
  if grep -E "SCRIPT ERROR|^ERROR:|Failed to load|ContentDB" "$LINUX_LOG" >/dev/null; then
    cat "$LINUX_LOG"
    echo "Exported Linux smoke errors detected." >&2
    exit 1
  fi
  echo "Linux export smoke: OK"
  if ! unzip -l build/android/abyssal-sovereign-debug.apk | grep -q "assets/content/core/classes.json"; then
    echo "Android debug APK is missing content/core JSON assets." >&2
    exit 1
  fi
  echo "Android debug APK asset check: OK"
fi

echo "==> Regression verification passed."
