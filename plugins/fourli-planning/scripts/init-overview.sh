#!/bin/sh
set -u

NAME="${1:-}"
NAME="$(printf "%s" "$NAME" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

[ -n "$NAME" ] || {
    echo "Usage: init-overview.sh \"任务名\"" >&2
    exit 2
}

case "$NAME" in
    */*|*..*)
        echo "[fourli-planning] invalid task name: must not contain / or .." >&2
        exit 2
        ;;
esac

DATE="$(date +%Y-%m-%d)"
PLAN_ROOT="docs/planning"
BASE_ID="${DATE}-${NAME}"
PLAN_ID="$BASE_ID"
COUNTER=2

mkdir -p "$PLAN_ROOT"
while [ -e "${PLAN_ROOT}/${PLAN_ID}" ]; do
    PLAN_ID="${BASE_ID}-${COUNTER}"
    COUNTER=$((COUNTER + 1))
done

PLAN_DIR="${PLAN_ROOT}/${PLAN_ID}"
mkdir -p "$PLAN_DIR"
OVERVIEW="${PLAN_DIR}/overview.md"

cat > "$OVERVIEW" << EOF
<!-- planning-lite:inject-start -->

# ${PLAN_ID}

## 总目标

一句话说明最终要达到什么状态。

## 边界

- 做什么：
- 不做什么：

## 阶段总览

| 阶段 | 状态 | 依赖 | superpowers 入口 | 验收 |
|------|------|------|------------------|------|
| 1. 需求边界确认 | in_progress | 无 | docs/superpowers/specs/... | 阶段级完成信号 |

## 当前交接

- 当前目标：
- 当前阶段：1. 需求边界确认
- 下一步：
- 最近完成：
- 不要做：
- 继续前必须看的 superpowers 文档：

<!-- planning-lite:inject-end -->

## 方向变更

-

## 关键证据

-

## 收尾记录

-
EOF

printf "%s\n" "$PLAN_ID" > "${PLAN_ROOT}/.active_plan"

echo "[fourli-planning] created ${OVERVIEW}"
echo "[fourli-planning] active planning: ${PLAN_ID}"
