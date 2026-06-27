#!/bin/sh
set -u

CHECKPOINT_FILE="${1:-}"
[ -n "$CHECKPOINT_FILE" ] && [ -f "$CHECKPOINT_FILE" ] || {
    echo "[fourli-checkpoint] checkpoint not found" >&2
    exit 1
}

START_COUNT=$(grep -c '<!-- fourli-checkpoint:inject-start -->' "$CHECKPOINT_FILE" || true)
END_COUNT=$(grep -c '<!-- fourli-checkpoint:inject-end -->' "$CHECKPOINT_FILE" || true)

[ "$START_COUNT" -eq 1 ] || {
    echo "[fourli-checkpoint] expected exactly one inject-start delimiter" >&2
    exit 2
}

[ "$END_COUNT" -eq 1 ] || {
    echo "[fourli-checkpoint] expected exactly one inject-end delimiter" >&2
    exit 3
}

BLOCK_OUTPUT="$(sh "$(dirname "$0")/extract-inject-block.sh" "$CHECKPOINT_FILE" 2>/dev/null)"
EXTRACT_STATUS=$?
[ "$EXTRACT_STATUS" -eq 0 ] || {
    echo "[fourli-checkpoint] injection block exceeds 60 lines or cannot be extracted" >&2
    exit 4
}

LINES=$(printf "%s\n" "$BLOCK_OUTPUT" | wc -l | tr -d ' ')
[ "$LINES" -le 60 ] || {
    echo "[fourli-checkpoint] injection block exceeds 60 lines" >&2
    exit 4
}

echo "[fourli-checkpoint] checkpoint OK"
