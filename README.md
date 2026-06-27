# Fourli Skills

`fourli-skills` 是一个可复用的开源 skills 包，用于在其他仓库开发时安装给 agent 使用。这个仓库本身只维护 skills、可选 hooks 和相关文档；真正的 checkpoint 文件会生成在使用者的目标项目里。

Codex 可以通过插件方式安装本仓库。非 Codex agent 后续也应能直接从根目录 `skills/` 安装或读取纯 skills。大多数后续能力都会是纯 skills，不依赖 hooks。

## 当前 skills

- `fourli-checkpoint`：用户显式触发，为大任务创建、查看或切换轻量 checkpoint。
- `fourli-checkpoint-maintenance`：agent-facing，只在已有 active checkpoint 且出现阶段边界、上下文接力风险、方向变更或任务收尾时维护 checkpoint。

## 目录结构

```text
.codex-plugin/
  plugin.json
skills/
  fourli-checkpoint/
  fourli-checkpoint-maintenance/
hooks/
  hooks.json
  session-start.sh
  pre-compact.sh
  stop.sh
docs/
```

## Codex 安装

```bash
codex plugin marketplace add /path/to/fourli-skills
```

Codex hooks 只是增强层：

- `SessionStart`：注入 active checkpoint 的 delimited block。
- `PreCompact`：用 JSON `systemMessage` 做非阻断提醒。
- `Stop`：用 JSON `systemMessage` 做非阻断提醒。

## 非 Codex 使用

非 Codex agent 应优先读取根目录 `skills/`。`hooks/` 不是必需能力；不支持 hooks 的 agent 可以通过目标项目的 `AGENTS.md` 指引触发 maintenance skill。

## 建议写入目标项目的 AGENTS.md

安装 `fourli-skills` 后，如果目标项目使用 checkpoint，建议把下面这段加入目标项目的 `AGENTS.md`，不是加入本仓库的 `AGENTS.md`：

```markdown
## Fourli Checkpoint

If `docs/checkpoints/.active_checkpoint` exists, use `fourli-checkpoint-maintenance` only at session start/resume, phase boundaries, context handoff risk, direction changes, or task closeout.

For orientation, read only the delimited checkpoint inject block first. Read the full `checkpoint.md` only when updating direction changes, key evidence, closeout notes, closing the checkpoint, or repairing the checkpoint file.

Do not use checkpoint content as an implementation plan. The primary workflow owns requirements design, implementation planning, execution, and verification.
```

## checkpoint 边界

- checkpoint 只记录大任务接力状态。
- checkpoint 不是需求设计。
- checkpoint 不是 implementation plan。
- checkpoint 不是执行日志。
- checkpoint 不是验证记录。
