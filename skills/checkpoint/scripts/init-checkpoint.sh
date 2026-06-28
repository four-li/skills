#!/bin/sh
set -u

NAME="${1:-}"
NAME="$(printf "%s" "$NAME" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

[ -n "$NAME" ] || {
    echo "Usage: init-checkpoint.sh \"任务名\"" >&2
    exit 2
}

case "$NAME" in
    */*|*..*)
        echo "[fourli-checkpoint] invalid checkpoint name: must not contain / or .." >&2
        exit 2
        ;;
esac

DATE="$(date +%Y-%m-%d)"
CHECKPOINT_ROOT="docs/checkpoints"
BASE_ID="${DATE}-${NAME}"
CHECKPOINT_ID="$BASE_ID"
COUNTER=2

mkdir -p "$CHECKPOINT_ROOT"
while [ -e "${CHECKPOINT_ROOT}/${CHECKPOINT_ID}" ]; do
    CHECKPOINT_ID="${BASE_ID}-${COUNTER}"
    COUNTER=$((COUNTER + 1))
done

CHECKPOINT_DIR="${CHECKPOINT_ROOT}/${CHECKPOINT_ID}"
mkdir -p "$CHECKPOINT_DIR"
CHECKPOINT_FILE="${CHECKPOINT_DIR}/checkpoint.md"

cat > "$CHECKPOINT_FILE" << EOF
<!-- fourli-checkpoint:inject-start -->

# ${CHECKPOINT_ID}

## 总目标

一句话说明最终要达到什么状态。

## 边界

- 做什么：
- 不做什么：

## 阶段地图

| 阶段 | 状态 | 依赖 | 主工作流入口 | 完成信号 |
|------|------|------|--------------|----------|
| P1 需求边界确认 | pending | 无 | 未开始 | 待主工作流确认 |

## 当前接力

- 当前阶段：P1 需求边界确认
- 下一步：为 P1 启动主工作流。
- 最近完成：checkpoint 已创建。
- 注意事项：阶段地图允许后续按主工作流发现动态调整。
- 继续前必须看：无

<!-- fourli-checkpoint:inject-end -->

## 方向变更

-

## 关键证据

-

## 收尾记录

-
EOF

printf "%s\n" "$CHECKPOINT_ID" > "${CHECKPOINT_ROOT}/.active_checkpoint"

echo "[fourli-checkpoint] created ${CHECKPOINT_FILE}"
echo "[fourli-checkpoint] active checkpoint: ${CHECKPOINT_ID}"
