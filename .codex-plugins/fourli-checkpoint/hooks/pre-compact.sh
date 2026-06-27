#!/bin/sh
set -u

ROOT="${PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
RESOLVER="${ROOT}/skills/fourli/checkpoint-maintenance/scripts/resolve-checkpoint.sh"
EMITTER="${ROOT}/hooks/emit-json.py"

CHECKPOINT_FILE="$(sh "$RESOLVER" 2>/dev/null)" || exit 0
[ -n "$CHECKPOINT_FILE" ] || exit 0

{
    echo "[fourli-checkpoint] Active checkpoint exists."
    echo "Before compaction, update it only if this turn reached a phase boundary, changed direction, created handoff risk, or completed the overall task."
    echo "Do not update checkpoint for ordinary execution progress."
} | python3 "$EMITTER" "PreCompact" "systemMessage"
