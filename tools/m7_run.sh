#!/usr/bin/env bash
# M7.1 reproducible soak driver: shards across cores, then summarizes.
#   tools/m7_run.sh TAG [--seeds=N] [--salt=SALT] [--set=dev|validation] [--policies=a,b] [--jobs=N] [--adaptive=N]
# Raw JSONL goes to balance/raw/TAG.shardK.jsonl (gitignored); the summary to balance/TAG_summary.{json,md}.
# --adaptive=N runs a second round of N extra seeds, only on the pairs m7_report flags as suspect.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-}"
[ -z "$GODOT" ] && { [ -x ./.tools/godot ] && GODOT=./.tools/godot || GODOT=godot; }
TAG="${1:?usage: m7_run.sh TAG [options]}"; shift
SEEDS=2; SALT=m7dev; SET=dev; POLICIES=""; JOBS="$(nproc)"; ADAPT=0; EXTRA=()
for a in "$@"; do
  case "$a" in
    --seeds=*) SEEDS="${a#*=}" ;; --salt=*) SALT="${a#*=}" ;; --set=*) SET="${a#*=}" ;;
    --policies=*) POLICIES="${a#*=}" ;; --jobs=*) JOBS="${a#*=}" ;; --adaptive=*) ADAPT="${a#*=}" ;;
    *) EXTRA+=("$a") ;;
  esac
done
mkdir -p balance/raw
round() { # name seeds seed_from [pairs]
  local name="$1" seeds="$2" from="$3" pairs="${4:-}"
  local pids=()
  for ((k = 0; k < JOBS; k++)); do
    args=(--set="$SET" --salt="$SALT" --seeds="$seeds" --seed-from="$from" --shard="$k/$JOBS" --out="balance/raw/$name.shard$k.jsonl")
    [ -n "$POLICIES" ] && args+=(--policies="$POLICIES")
    [ -n "$pairs" ] && args+=(--pairs="$pairs")
    "$GODOT" --headless --path . --script res://tools/m7_soak.gd -- "${args[@]}" "${EXTRA[@]}" >"balance/raw/$name.shard$k.log" 2>&1 &
    pids+=($!)
  done
  for p in "${pids[@]}"; do wait "$p" || echo "shard pid $p failed" >&2; done
}
round "$TAG.r1" "$SEEDS" 0
if [ "$ADAPT" -gt 0 ]; then
  SUS="$("$GODOT" --headless --path . --script res://tools/m7_report.gd -- --in=balance/raw --filter="$TAG.r1" --suspects | tail -1)"
  echo "adaptive round: suspects=[$SUS]"
  [ -n "$SUS" ] && round "$TAG.r2" "$ADAPT" "$SEEDS" "$SUS"
fi
"$GODOT" --headless --path . --script res://tools/m7_report.gd -- --in=balance/raw --filter="$TAG." --out="balance/$TAG" | tail -n +1 >/dev/null
echo "summary: balance/${TAG}_summary.md"
