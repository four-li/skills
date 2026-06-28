#!/bin/sh
set -u

ROOT="${PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
SCRIPT_ROOT="${ROOT}/skills/checkpoint-maintenance/scripts"
RESOLVER="${SCRIPT_ROOT}/resolve-checkpoint.sh"
EXTRACTOR="${SCRIPT_ROOT}/extract-inject-block.sh"
EMITTER="${ROOT}/hooks/emit-json.py"

CHECKPOINT_FILE="$(sh "$RESOLVER" 2>/dev/null)" || exit 0
[ -n "$CHECKPOINT_FILE" ] || exit 0

CHECKPOINT_ID_VALUE="$(basename "$(dirname "$CHECKPOINT_FILE")")"
BLOCK="$(sh "$EXTRACTOR" "$CHECKPOINT_FILE" 2>/dev/null)"
STATUS=$?

if [ "$STATUS" -ne 0 ]; then
    printf "%s\n" "[fourli-checkpoint] active checkpoint exists but injection delimiters need repair: ${CHECKPOINT_FILE}" | python3 "$EMITTER" "SessionStart" "additionalContext"
    exit 0
fi

{
    echo "[fourli-checkpoint]"
    echo "role: checkpoint handoff only"
    echo "checkpoint: ${CHECKPOINT_ID_VALUE}"
    echo "rules:"
    echo "- checkpoint.md is a handoff index, not a requirements design, implementation plan, execution log, or verification record."
    echo "- Read the delimited block for orientation; read the full file only when maintenance is needed."
    echo "===BEGIN FOURLI CHECKPOINT==="
    printf "%s\n" "$BLOCK"
    echo "===END FOURLI CHECKPOINT==="
} | python3 "$EMITTER" "SessionStart" "additionalContext"
