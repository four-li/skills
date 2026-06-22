#!/bin/sh
set -u

PLAN_ROOT="docs/planning"
ACTIVE_FILE="${PLAN_ROOT}/.active_plan"
PLAN_ID_VALUE="${1:-}"

if [ -z "$PLAN_ID_VALUE" ]; then
    if [ -f "$ACTIVE_FILE" ]; then
        current="$(cat "$ACTIVE_FILE" 2>/dev/null)"
        if [ -n "$current" ] && [ -f "${PLAN_ROOT}/${current}/overview.md" ]; then
            echo "Active planning: ${current}"
            echo "Path: ${PLAN_ROOT}/${current}/overview.md"
        else
            echo "No valid active planning."
        fi
    else
        echo "No active planning."
    fi
    exit 0
fi

case "$PLAN_ID_VALUE" in
    */*|*..*)
        echo "[fourli-planning] invalid plan id" >&2
        exit 2
        ;;
esac

OVERVIEW="${PLAN_ROOT}/${PLAN_ID_VALUE}/overview.md"
[ -f "$OVERVIEW" ] || {
    echo "[fourli-planning] overview not found: ${OVERVIEW}" >&2
    exit 1
}

mkdir -p "$PLAN_ROOT"
printf "%s\n" "$PLAN_ID_VALUE" > "$ACTIVE_FILE"
echo "[fourli-planning] active planning: ${PLAN_ID_VALUE}"
