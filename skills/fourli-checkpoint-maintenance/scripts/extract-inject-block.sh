#!/bin/sh
set -u

CHECKPOINT_FILE="${1:-}"
[ -n "$CHECKPOINT_FILE" ] && [ -f "$CHECKPOINT_FILE" ] || exit 1

awk '
    /<!-- fourli-checkpoint:inject-start -->/ { in_block=1; seen_start=1; next }
    /<!-- fourli-checkpoint:inject-end -->/ { seen_end=1; exit }
    in_block {
        count++
        if (count <= 60) print
    }
    END {
        if (!seen_start || !seen_end) exit 2
        if (count > 60) exit 3
    }
' "$CHECKPOINT_FILE"
