#!/bin/sh
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLAN_ROOT="docs/planning"
ACTIVE_FILE="${PLAN_ROOT}/.active_plan"

PLAN_ID_VALUE="${1:-}"
if [ -z "$PLAN_ID_VALUE" ]; then
    [ -f "$ACTIVE_FILE" ] || {
        echo "[fourli-planning] no active planning"
        exit 0
    }
    PLAN_ID_VALUE="$(cat "$ACTIVE_FILE" 2>/dev/null)"
fi

case "$PLAN_ID_VALUE" in
    ""|*/*|*..*)
        echo "[fourli-planning] invalid plan id" >&2
        exit 2
        ;;
esac

OVERVIEW="${PLAN_ROOT}/${PLAN_ID_VALUE}/overview.md"
[ -f "$OVERVIEW" ] || {
    echo "[fourli-planning] overview not found: ${OVERVIEW}" >&2
    exit 1
}

sh "${SCRIPT_DIR}/validate-overview.sh" "$OVERVIEW" >/dev/null || {
    echo "[fourli-planning] overview template needs repair before finish: ${OVERVIEW}" >&2
    exit 1
}

if [ -f "$ACTIVE_FILE" ] && [ "$(cat "$ACTIVE_FILE" 2>/dev/null)" = "$PLAN_ID_VALUE" ]; then
    rm -f "$ACTIVE_FILE"
    echo "[fourli-planning] cleared active planning: ${PLAN_ID_VALUE}"
else
    echo "[fourli-planning] overview is not current active planning: ${PLAN_ID_VALUE}"
fi

echo "[fourli-planning] historical overview kept: ${OVERVIEW}"
