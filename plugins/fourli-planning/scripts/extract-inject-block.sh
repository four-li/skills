#!/bin/sh
set -u

OVERVIEW="${1:-}"
[ -n "$OVERVIEW" ] && [ -f "$OVERVIEW" ] || exit 1

awk '
    /<!-- planning-lite:inject-start -->/ { in_block=1; seen_start=1; next }
    /<!-- planning-lite:inject-end -->/ { seen_end=1; exit }
    in_block {
        count++
        if (count <= 60) print
    }
    END {
        if (!seen_start || !seen_end) exit 2
        if (count > 60) exit 3
    }
' "$OVERVIEW"
