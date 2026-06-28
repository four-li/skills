#!/bin/sh
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHECKPOINT_ROOT="docs/checkpoints"
ACTIVE_FILE="${CHECKPOINT_ROOT}/.active_checkpoint"

CHECKPOINT_ID_VALUE="${1:-}"
if [ -z "$CHECKPOINT_ID_VALUE" ]; then
    [ -f "$ACTIVE_FILE" ] || {
        echo "[fourli-checkpoint] no active checkpoint"
        exit 0
    }
    CHECKPOINT_ID_VALUE="$(cat "$ACTIVE_FILE" 2>/dev/null)"
fi

case "$CHECKPOINT_ID_VALUE" in
    ""|*/*|*..*)
        echo "[fourli-checkpoint] invalid checkpoint id" >&2
        exit 2
        ;;
esac

CHECKPOINT_FILE="${CHECKPOINT_ROOT}/${CHECKPOINT_ID_VALUE}/checkpoint.md"
[ -f "$CHECKPOINT_FILE" ] || {
    echo "[fourli-checkpoint] checkpoint not found: ${CHECKPOINT_FILE}" >&2
    exit 1
}

sh "${SCRIPT_DIR}/validate-checkpoint.sh" "$CHECKPOINT_FILE" >/dev/null || {
    echo "[fourli-checkpoint] checkpoint template needs repair before finish: ${CHECKPOINT_FILE}" >&2
    exit 1
}

if [ -f "$ACTIVE_FILE" ] && [ "$(cat "$ACTIVE_FILE" 2>/dev/null)" = "$CHECKPOINT_ID_VALUE" ]; then
    rm -f "$ACTIVE_FILE"
    echo "[fourli-checkpoint] cleared active checkpoint: ${CHECKPOINT_ID_VALUE}"
else
    echo "[fourli-checkpoint] checkpoint is not current active checkpoint: ${CHECKPOINT_ID_VALUE}"
fi

echo "[fourli-checkpoint] historical checkpoint kept: ${CHECKPOINT_FILE}"
