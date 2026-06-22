#!/bin/sh
set -u

ROOT="${PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
OVERVIEW="$(sh "${ROOT}/scripts/resolve-overview.sh" 2>/dev/null)" || exit 0
[ -n "$OVERVIEW" ] || exit 0

echo "[planning-lite] 上下文即将压缩。请确认 overview.md 已记录当前交接、下一步、方向变更。"
echo "overview.md 只是总进度索引；具体 spec/plan/execute/verification 仍以 superpowers 为准。"
