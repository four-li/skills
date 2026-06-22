#!/bin/sh
set -u

ROOT="${PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
OVERVIEW="$(sh "${ROOT}/scripts/resolve-overview.sh" 2>/dev/null)" || exit 0
[ -n "$OVERVIEW" ] || exit 0

PLAN_ID_VALUE="$(basename "$(dirname "$OVERVIEW")")"

echo "[planning-lite] 当前存在 active planning：${PLAN_ID_VALUE}"
echo "结束前请确认 overview.md 是否需要更新：阶段边界、当前交接、下一步、方向变更。"
echo "如果你刚完成一个阶段，请把下一窗口需要知道的 3 件事写进 overview.md：当前状态、下一步、注意事项。"
echo "如果该总任务已完成，请运行 finish-overview.sh 清理 active planning，避免后续窗口继续注入旧 overview。"
echo "overview.md 只是总进度索引；具体 spec/plan/execute/verification 仍以 superpowers 为准。"
exit 0
