# Fourli Skills

`fourli-skills` 是一个给 AI agent 安装的轻量 skills 包，当前主要提供大任务接力用的 checkpoint 能力。仓库本身只维护 skills、可选 hooks 和相关文档；真正的 checkpoint 运行文件会生成在使用它的目标项目里。

## 适用范围

- 适合需要在长任务、多阶段任务、跨会话任务之间做接力的项目。
- 当前主要面向 Codex 使用，也尽量保持 `skills/` 目录可以被其他兼容 skills 的 agent 直接读取。
- `hooks/` 只是 Codex 的增强层，不是核心依赖。

## 安装

### Codex

公开使用时，优先把这个仓库作为 Git marketplace 加入：

```bash
codex plugin marketplace add four-li/skills
```

### npx skills

如果你使用支持 [skills](https://github.com/vercel-labs/skills) CLI 的 agent，也可以直接从这个仓库安装。

先查看仓库里有哪些 skill：

```bash
npx skills add four-li/skills --list
```

例如，把 skill 全局安装给 `trae-cn`：

```bash
npx skills add four-li/skills --agent trae-cn -g -y
```

这个仓库当前已经可以被 `npx skills add` 直接识别，不需要额外的配置文件。能工作的关键是仓库根目录下存在符合约定的 `skills/<skill-name>/SKILL.md` 结构。

如果你是全局安装，后续只更新这个仓库安装出来的 skills，可以执行：

```bash
npx skills update -g fourli-checkpoint fourli-checkpoint-maintenance
```

如果只想先看当前全局装了什么，可以先执行：

```bash
npx skills list -g
```

### 其他兼容 skills 的 agent

优先读取仓库根目录下的 `skills/`。这个仓库的核心能力都放在这里。

如果目标 agent 不支持 hooks，也可以只使用 `skills/`，再通过项目级或用户级 `AGENTS.md` 约束何时触发 maintenance skill。

## 包含的 Skills

| Skill | 什么时候用 | 作用 |
| --- | --- | --- |
| `fourli-checkpoint` | 用户明确要求创建、查看或切换 checkpoint 时 | 创建或切换一个轻量 checkpoint，用来记录大任务的接力状态 |
| `fourli-checkpoint-maintenance` | 已有 active checkpoint，且进入阶段边界、方向变更、上下文接力风险或任务收尾时 | 维护 checkpoint 内容，保证接力信息短、准、可继续 |

## 可选 Hooks

Codex hooks 只是增强层，用来减少 agent 漏掉 checkpoint 维护的概率：

- `SessionStart`：注入 active checkpoint 的定界文本块，先给 agent 一个短摘要。
- `PreCompact`：通过 JSON `systemMessage` 做非阻断提醒。
- `Stop`：通过 JSON `systemMessage` 做非阻断提醒。

如果没有 hooks，skills 仍然可以工作，只是更依赖目标项目里的使用约定。

## 仓库结构

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

## 建议写入 AGENTS.md

默认建议把下面这段加入“会实际使用 checkpoint 的目标项目”的 `AGENTS.md`，不是加入本仓库的 `AGENTS.md`。

这样更稳妥，原因有两个：

- 这条规则是项目工作流约束，不是所有项目都应该默认启用。
- 它引用的是项目内路径 `docs/checkpoints/.active_checkpoint`，天然更适合项目级生效。

如果你个人所有项目都统一使用这套 checkpoint 工作流，也可以把同一段规则加到用户级全局 `AGENTS.md`，但那应该算你的个人默认工作方式，而不是这个仓库的默认推荐。

```markdown
## Fourli Checkpoint

If `docs/checkpoints/.active_checkpoint` exists, use `fourli-checkpoint-maintenance` only at session start/resume, phase boundaries, context handoff risk, direction changes, or task closeout.

For orientation, read only the delimited checkpoint inject block first. Read the full `checkpoint.md` only when updating direction changes, key evidence, closeout notes, closing the checkpoint, or repairing the checkpoint file.

Do not use checkpoint content as an implementation plan. The primary workflow owns requirements design, implementation planning, execution, and verification.
```

## Checkpoint 边界

checkpoint 只负责记录大任务接力状态，不负责替代主工作流。具体来说：

- checkpoint 不是需求设计。
- checkpoint 不是 implementation plan。
- checkpoint 不是执行日志。
- checkpoint 不是验证记录。

如果你需要的是“定义要做什么”“拆解怎么做”“记录每一步执行结果”，这些内容应该留在主工作流自己的 spec、plan 和验证产物里，而不是堆进 checkpoint。
