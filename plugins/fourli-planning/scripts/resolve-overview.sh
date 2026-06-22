#!/bin/sh
set -u

PLAN_ROOT="docs/planning"
ACTIVE_FILE="${PLAN_ROOT}/.active_plan"

clean_id() {
    printf "%s" "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

valid_id() {
    id="$1"
    [ -n "$id" ] || return 1
    case "$id" in
        */*|*..*) return 1 ;;
    esac
    return 0
}

canonicalize() {
    target="$1"
    if command -v realpath >/dev/null 2>&1; then
        realpath "$target" 2>/dev/null && return 0
    fi
    if command -v python3 >/dev/null 2>&1; then
        python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$target" 2>/dev/null && return 0
    fi
    return 1
}

within_plan_root() {
    candidate="$1"
    root_real="$(canonicalize "$PLAN_ROOT")" || return 1
    cand_real="$(canonicalize "$candidate")" || return 1
    case "$cand_real" in
        "$root_real"/*) return 0 ;;
        *) return 1 ;;
    esac
}

resolve_id() {
    if [ -n "${PLAN_ID:-}" ]; then
        clean_id "$PLAN_ID"
        return 0
    fi
    [ -f "$ACTIVE_FILE" ] || return 1
    clean_id "$(cat "$ACTIVE_FILE" 2>/dev/null)"
}

[ -d "$PLAN_ROOT" ] || exit 0
PLAN_ID_VALUE="$(resolve_id)" || exit 0
valid_id "$PLAN_ID_VALUE" || exit 0

OVERVIEW="${PLAN_ROOT}/${PLAN_ID_VALUE}/overview.md"
[ -f "$OVERVIEW" ] || exit 0
within_plan_root "$OVERVIEW" || exit 0

printf "%s\n" "$OVERVIEW"
