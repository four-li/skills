#!/bin/sh
set -u

ROOT="${PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
RESOLVER="${ROOT}/skills/fourli-checkpoint-maintenance/scripts/resolve-checkpoint.sh"
EMITTER="${ROOT}/hooks/emit-json.py"

CHECKPOINT_FILE="$(sh "$RESOLVER" 2>/dev/null)" || exit 0
[ -n "$CHECKPOINT_FILE" ] || exit 0

CHECKPOINT_ID_VALUE="$(basename "$(dirname "$CHECKPOINT_FILE")")"

{
    echo "[fourli-checkpoint] Active checkpoint: ${CHECKPOINT_ID_VALUE}"
    echo "Before stopping, update checkpoint only if this turn completed a phase, changed the phase map, created handoff risk, or completed the overall task."
    echo "If the overall task is complete, run finish-checkpoint.sh to clear the active checkpoint."
    echo "Do not update checkpoint for ordinary execution progress."
} | python3 "$EMITTER" "Stop" "systemMessage"
