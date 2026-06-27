#!/bin/sh
set -u

CHECKPOINT_ROOT="docs/checkpoints"
ACTIVE_FILE="${CHECKPOINT_ROOT}/.active_checkpoint"
CHECKPOINT_ID_VALUE="${1:-}"

if [ -z "$CHECKPOINT_ID_VALUE" ]; then
    if [ -f "$ACTIVE_FILE" ]; then
        current="$(cat "$ACTIVE_FILE" 2>/dev/null)"
        if [ -n "$current" ] && [ -f "${CHECKPOINT_ROOT}/${current}/checkpoint.md" ]; then
            echo "Active checkpoint: ${current}"
            echo "Path: ${CHECKPOINT_ROOT}/${current}/checkpoint.md"
        else
            echo "No valid active checkpoint."
        fi
    else
        echo "No active checkpoint."
    fi
    exit 0
fi

case "$CHECKPOINT_ID_VALUE" in
    */*|*..*)
        echo "[fourli-checkpoint] invalid checkpoint id" >&2
        exit 2
        ;;
esac

CHECKPOINT_FILE="${CHECKPOINT_ROOT}/${CHECKPOINT_ID_VALUE}/checkpoint.md"
[ -f "$CHECKPOINT_FILE" ] || {
    echo "[fourli-checkpoint] checkpoint not found: ${CHECKPOINT_FILE}" >&2
    exit 1
}

mkdir -p "$CHECKPOINT_ROOT"
printf "%s\n" "$CHECKPOINT_ID_VALUE" > "$ACTIVE_FILE"
echo "[fourli-checkpoint] active checkpoint: ${CHECKPOINT_ID_VALUE}"
