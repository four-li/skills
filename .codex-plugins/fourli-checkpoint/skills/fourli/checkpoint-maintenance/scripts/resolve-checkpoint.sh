#!/bin/sh
set -u

CHECKPOINT_ROOT="docs/checkpoints"
ACTIVE_FILE="${CHECKPOINT_ROOT}/.active_checkpoint"

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

within_checkpoint_root() {
    candidate="$1"
    root_real="$(canonicalize "$CHECKPOINT_ROOT")" || return 1
    cand_real="$(canonicalize "$candidate")" || return 1
    case "$cand_real" in
        "$root_real"/*) return 0 ;;
        *) return 1 ;;
    esac
}

resolve_id() {
    if [ -n "${CHECKPOINT_ID:-}" ]; then
        clean_id "$CHECKPOINT_ID"
        return 0
    fi
    [ -f "$ACTIVE_FILE" ] || return 1
    clean_id "$(cat "$ACTIVE_FILE" 2>/dev/null)"
}

[ -d "$CHECKPOINT_ROOT" ] || exit 0
CHECKPOINT_ID_VALUE="$(resolve_id)" || exit 0
valid_id "$CHECKPOINT_ID_VALUE" || exit 0

CHECKPOINT_FILE="${CHECKPOINT_ROOT}/${CHECKPOINT_ID_VALUE}/checkpoint.md"
[ -f "$CHECKPOINT_FILE" ] || exit 0
within_checkpoint_root "$CHECKPOINT_FILE" || exit 0

printf "%s\n" "$CHECKPOINT_FILE"
