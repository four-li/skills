#!/bin/sh
set -u

OVERVIEW="${1:-}"
[ -n "$OVERVIEW" ] && [ -f "$OVERVIEW" ] || {
    echo "[fourli-planning] overview not found"
    exit 1
}

START_COUNT=$(grep -c '<!-- planning-lite:inject-start -->' "$OVERVIEW" || true)
END_COUNT=$(grep -c '<!-- planning-lite:inject-end -->' "$OVERVIEW" || true)

[ "$START_COUNT" -eq 1 ] || {
    echo "[fourli-planning] expected exactly one inject-start delimiter"
    exit 2
}

[ "$END_COUNT" -eq 1 ] || {
    echo "[fourli-planning] expected exactly one inject-end delimiter"
    exit 3
}

LINES=$(sh "$(dirname "$0")/extract-inject-block.sh" "$OVERVIEW" 2>/dev/null | wc -l | tr -d ' ')
[ "$LINES" -le 60 ] || {
    echo "[fourli-planning] injection block exceeds 60 lines"
    exit 4
}

echo "[fourli-planning] overview OK"
