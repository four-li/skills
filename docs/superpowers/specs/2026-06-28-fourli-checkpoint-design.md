# Fourli Checkpoint 设计

> 纠偏说明：本设计最初按单个 Codex 插件目录讨论，后续已修正为开源 `fourli-skills` 包结构。最终实现以根目录 `.codex-plugin/`、`skills/`、`hooks/` 为准；`.codex-plugins/fourli-checkpoint/` 不再作为目标结构。

## 目标

将现有 `fourli-planning` 重构为 `fourli-checkpoint`。新能力只为大任务提供轻量接力检查点，帮助新窗口或后续 agent 恢复“当前做到了哪里、下一步看哪里、哪些方向变了”。

checkpoint 不是需求设计、不是实现计划、不是执行日志、不是验证记录。如果项目使用 superpowers，spec、writing-plans、execution、verification 仍由 superpowers 负责；如果项目使用其他主工作流，也由对应主工作流负责。

## 非目标

- 不兼容旧的 `docs/planning/`、`.active_plan`、`overview.md`、`fourli-planning`。
- 不保留旧 skill alias，不保留旧插件目录。
- 不维护细粒度 todolist 或 implementation checklist。
- 不复制 superpowers 的 spec、plan、执行过程或验证细节。
- 不在 `PreCompact` 或 `Stop` 默认阻断用户流程。

## 命名与目录

插件目录改为：

```text
.codex-plugins/fourli-checkpoint/
```

项目运行文件改为：

```text
docs/checkpoints/
  .active_checkpoint
  <checkpoint-id>/
    checkpoint.md
```

旧目录处理：

- 删除 `plugins/fourli-planning/`。
- 删除 `.codex-plugins/fourli-planning/`。
- `marketplace.json` 只暴露 `fourli-checkpoint`。
- README 只说明 `fourli-checkpoint`。

## Skill 分工

### `fourli/checkpoint`

用户显式入口。只在用户明确要求创建、查看或切换 checkpoint 时使用。

创建 checkpoint 时允许阶段地图粗糙、不完整；只要求有总目标和至少一个可开始的粗阶段。agent 不能为了完善阶段地图持续追问用户，也不能替代主工作流做需求细化。

职责：

- 创建 `docs/checkpoints/<checkpoint-id>/checkpoint.md`。
- 写入或切换 `docs/checkpoints/.active_checkpoint`。
- 查看当前 active checkpoint。
- 保持阶段地图粗粒度。

### `fourli/checkpoint-maintenance`

agent-facing 维护入口。只在已有 active checkpoint 且出现以下情况时使用：

- session start/resume 需要恢复方向。
- 一个阶段到达边界。
- 上下文交接风险出现。
- 方向变更影响阶段地图。
- 大任务整体完成，需要关闭 active checkpoint。

不因普通执行进度、小测试通过、实现 checklist 前进一项而触发。

维护内容只限：

- 阶段状态：`pending`、`in_progress`、`complete`。
- 当前接力：当前阶段、下一步、最近完成、注意事项、必须看的主工作流文档。
- 主工作流入口：如 superpowers spec/plan 链接。
- 方向变更：为什么变、影响什么、下一步怎么变。
- 关键证据：只记录影响后续判断的事实。

## `checkpoint.md` 结构

文件分为“注入区”和“历史区”。

注入区用于新窗口快速恢复方向，必须由 marker 包住，最多 60 行：

```markdown
<!-- fourli-checkpoint:inject-start -->

# 2026-06-28-i18n

## 总目标

让项目的用户可见文案支持国际化，优先处理高频路径。

## 边界

- 做什么：异常信息、接口动态信息、数据库字段、必要的页面/菜单/tab 文案。
- 不做什么：不重写业务结构，不在 checkpoint 里维护实现清单。

## 阶段地图

| 阶段 | 状态 | 依赖 | 主工作流入口 | 完成信号 |
|------|------|------|--------------|----------|
| P1 静态异常信息 | pending | 无 | 未开始 | 待 SP 确认 |
| P2 三方接口动态信息 | pending | P1 | 未开始 | 待 SP 确认 |
| P3 DB 字段国际化 | pending | P2 | 未开始 | 进入前需重新评估范围 |

## 当前接力

- 当前阶段：P1 静态异常信息
- 下一步：为 P1 启动主工作流。
- 最近完成：checkpoint 已创建。
- 注意事项：DB 字段阶段可能过重，进入前先重新评估。
- 继续前必须看：无

<!-- fourli-checkpoint:inject-end -->
```

历史区位于 marker 外：

```markdown
## 方向变更

-

## 关键证据

-

## 收尾记录

-
```

普通恢复方向时只读注入区。只有更新方向变更、关键证据、收尾记录、关闭 checkpoint 或修复文件结构时，才读完整 `checkpoint.md`。

## 动态阶段地图

阶段地图允许随着主工作流发现事实而调整，但必须轻量。

允许：

- 插入新阶段，例如在接口动态信息后发现页面、菜单、tab 也需要翻译。
- 插入前置阶段，例如 DB 字段国际化前必须先做基础方法。
- 拆分过重阶段，例如把 DB 国际化拆为 P4a、P4b、P4c。
- 顺延后续阶段。

要求：

- 每次调整只改粗阶段，不写细实现步骤。
- 在“方向变更”里写一句原因和影响。
- 阶段编号不要求永远整齐；优先保持旧引用可追溯。

示例：

```markdown
| P3 页面/菜单/tab 基础文案 | pending | P2 | 未开始 | 待 SP |
| P4 DB 字段国际化 | pending | P3 | 未开始 | 待 SP |
```

```markdown
- 2026-06-28：P2 后发现页面/菜单/tab 文案缺口，插入 P3；DB 字段顺延。
```

## Hook 设计

Codex hooks 是增强层，不是唯一机制。不支持 hooks 的 agent 依靠 `AGENTS.md` 和 `fourli/checkpoint-maintenance` 的 description 触发。

`SessionStart`：

- 解析 active checkpoint。
- 提取 inject block。
- 输出 JSON，并通过 `hookSpecificOutput.additionalContext` 注入上下文。
- 不使用普通 stdout 作为协议输出。

`PreCompact`：

- 不默认阻断。
- 输出 JSON `systemMessage`，提醒仅在阶段边界、方向变更或接力风险存在时更新 checkpoint。
- 不依赖普通 stdout，因为该事件的普通 stdout 会被忽略。

`Stop`：

- 不默认阻断。
- 输出 JSON `systemMessage`，提醒如果本轮完成阶段或改变方向，应使用 maintenance 更新。
- 不使用纯 `echo`，因为成功退出时普通 stdout 不是有效 hook 输出。

## AGENTS.md 示例

面向普通不支持 hooks 的 agent，建议项目加入类似说明：

```markdown
## Fourli Checkpoint

If `docs/checkpoints/.active_checkpoint` exists, use `fourli/checkpoint-maintenance` only at session start/resume, phase boundaries, context handoff risk, direction changes, or task closeout.

For orientation, read only the delimited checkpoint inject block first. Read the full `checkpoint.md` only when updating direction changes, key evidence, closeout notes, closing the checkpoint, or repairing the checkpoint file.

Do not use checkpoint content as an implementation plan. The primary workflow owns requirements design, implementation planning, execution, and verification.
```

## 脚本位置

业务运行时脚本放到对应 skill 下，让 Codex 和普通 agent 都能从 skill 找到脚本。

```text
skills/fourli/checkpoint/scripts/
  init-checkpoint.sh
  set-active-checkpoint.sh

skills/fourli/checkpoint-maintenance/scripts/
  resolve-checkpoint.sh
  extract-inject-block.sh
  validate-checkpoint.sh
  finish-checkpoint.sh
```

插件根目录 `hooks/` 只保留 Codex 生命周期 wrapper。插件根目录不放业务运行时脚本；若未来需要安装、同步、发布辅助脚本，可放在插件或仓库的 `scripts/`，但不能与 checkpoint 运行时职责混在一起。

## 文档语言

- agent-facing 的 `description`、触发条件、Always/Never 规则使用英文。
- README、安装说明、设计理念中文为主。
- `checkpoint.md` 模板中文为主。
- 状态值固定为 `pending`、`in_progress`、`complete`。

## 验收标准

- 创建 checkpoint 后，生成 `docs/checkpoints/<checkpoint-id>/checkpoint.md` 和 `.active_checkpoint`。
- active 解析只读取显式 id 或 `.active_checkpoint`，不 fallback 到最新目录。
- inject 提取只读取 marker 内内容，并限制在 60 行以内。
- finish 会清除 `.active_checkpoint`，但保留历史 `checkpoint.md`。
- `SessionStart`、`PreCompact`、`Stop` 输出合法 JSON，且不依赖普通 stdout。
- 新 README、marketplace、skill 名称和用户可见文案不再使用 `planning` 作为主概念。
- `fourli/checkpoint` 不追问完整需求，不启动主工作流，只创建粗接力框架。
- `fourli/checkpoint-maintenance` 不因普通执行进度更新 checkpoint。
