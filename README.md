# Fourli Skills

`fourli-skills` 是一组给 AI agent 使用的 reusable skills（可复用技能）。它不是单一 checkpoint 插件，而是把我常用的几类工作方式拆成独立 skill：先想清楚、做技术讲解、简化代码、创建 checkpoint、维护 checkpoint。

## 包含的 Skills

| Skill | 什么时候用 | 作用 |
| --- | --- | --- |
| `think` | 需求还模糊、用户要求先想清楚，或已有 draft spec/design 需要被审问时 | 做短意图澄清，或审问草案里的歧义、边界、失败路径和验收标准 |
| `teacher` | 用户显式调用 `$teacher`、`teacher`，或要求用 teacher 调研/讲解技术问题时 | 联网查事实，用中文讲解技术、AI、项目、框架、架构概念和工程社区内容 |
| `code-opt` | 代码已经能工作，但结构、命名、重复或嵌套让它难读难维护时 | 在不改变行为的前提下简化代码 |
| `checkpoint` | 用户明确要求创建、查看或切换 checkpoint 时 | 创建或切换一个轻量 checkpoint，用来记录大任务的接力状态 |
| `checkpoint-maintenance` | 已有 active checkpoint，且进入阶段边界、方向变更、上下文接力风险或任务收尾时 | 维护 checkpoint 内容，保证接力信息短、准、可继续 |

## 安装

### Codex 插件

公开使用时，优先把这个仓库作为 Git marketplace 加入：

终端执行命令

```bash
codex plugin marketplace add four-li/skills
```

在 Codex App 里启用插件.(或codex cli中执行/plugins选择)后 `~/.codex/config.toml` 通常会出现：

```toml
[plugins."fourli-skills@fourli"]
enabled = true
```

### npx skills

例如，把这些 skills 全局安装给 `trae-cn`：

```bash
npx skills add four-li/skills --agent trae-cn -g -y
```

如果你是全局安装，后续只更新这个仓库安装出来的 skills，可以执行：

```bash
npx skills update -g think teacher code-opt checkpoint checkpoint-maintenance
```

### 其他兼容 skills 的 agent

优先读取仓库根目录下的 `skills/`。这个仓库的核心能力都在这里。

如果目标 agent 不支持 hooks，也可以只使用 `skills/`。其中 `checkpoint-maintenance` 会更依赖目标项目里的 `AGENTS.md` 约束来提醒 agent 何时触发。

## 可选 Hooks

Codex hooks 是增强层，用来减少 agent 漏掉 checkpoint 维护的概率：

- `SessionStart`：注入 active checkpoint 的定界文本块，先给 agent 一个短摘要。
- `PreCompact`：通过 JSON `systemMessage` 做非阻断提醒。
- `Stop`：通过 JSON `systemMessage` 做非阻断提醒。

没有 hooks 时，skills 仍然可以工作，只是 checkpoint 维护更依赖目标项目里的使用约定。

## Checkpoint 项目约定

如果agent没有加Hooks, 应把以下提示词加到AGENTS.md 

```markdown
## Fourli Checkpoint

If `docs/checkpoints/.active_checkpoint` exists, use `checkpoint-maintenance` only at session start/resume, phase boundaries, context handoff risk, direction changes, or task closeout.

For orientation, read only the delimited checkpoint inject block first. Read the full `checkpoint.md` only when updating direction changes, key evidence, closeout notes, closing the checkpoint, or repairing the checkpoint file.

Do not use checkpoint content as an implementation plan. The primary workflow owns requirements design, implementation planning, execution, and verification.
```

## Checkpoint 边界

checkpoint 只负责记录大任务接力状态，不负责替代主工作流。具体来说：

- checkpoint 不是需求设计。
- checkpoint 不是 implementation plan（实施计划，也就是拆解怎么做）。
- checkpoint 不是执行日志。
- checkpoint 不是验证记录。

如果你需要的是“定义要做什么”“拆解怎么做”“记录每一步执行结果”，这些内容应该留在主工作流自己的 spec、plan 和验证产物里，而不是堆进 checkpoint。
