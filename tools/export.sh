#!/usr/bin/env sh
# Export builds from the command line.
# Usage: tools/export.sh [linux|windows|web|android|all]
# Default: linux windows web
set -eu
cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT:-}"
if [ -z "$GODOT_BIN" ]; then
  if command -v godot >/dev/null 2>&1; then GODOT_BIN=godot
  elif [ -x ./.tools/godot ]; then GODOT_BIN=./.tools/godot
  else echo "Godot 4.7 not found: set GODOT=/path/to/godot" >&2; exit 2; fi
fi

TARGETS="$*"
if [ -z "$TARGETS" ]; then
  TARGETS="linux windows web"
elif [ "$TARGETS" = "all" ]; then
  TARGETS="linux windows web android"
fi

mkdir -p build test-results
touch build/.gdignore test-results/.gdignore
"$GODOT_BIN" --headless --path . --import >/dev/null 2>&1 || true

for t in $TARGETS; do
  case "$t" in
    linux)
      mkdir -p build/linux
      "$GODOT_BIN" --headless --path . --export-release "Linux" "build/linux/abyssal-sovereign.x86_64"
      ;;
    windows)
      mkdir -p build/windows
      "$GODOT_BIN" --headless --path . --export-release "Windows Desktop" "build/windows/abyssal-sovereign.exe"
      ;;
    web)
      mkdir -p build/web
      "$GODOT_BIN" --headless --path . --export-release "Web" "build/web/index.html"
      ;;
    android)
      mkdir -p build/android
      "$GODOT_BIN" --headless --path . --export-debug "Android" "build/android/abyssal-sovereign-debug.apk"
      ;;
    *)
      echo "Unknown export target: $t (expected linux, windows, web, android, or all)" >&2
      exit 2
      ;;
  esac
done
