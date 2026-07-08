# Fourli Skills — AGENTS.md

## 术语解释

有时候我喜欢用一个简短的词来代替一些特定含义，沟通时如果发现我说到这些 你按照下面的意思去理解

- sp :  代表superpowers这个SKILLS

---

## 项目概览

`fourli-skills` 是面向 AI 编码 agent（Codex / Claude / Trae 等）的**可复用 skills 集合**，不是单一应用程序。仓库同时也是 Codex / Claude Code 插件包，并可选提供 Codex hooks 增强 checkpoint 接力体验。

- **仓库主页**: https://github.com/four-li/skills
- **许可证**: MIT

## 目录结构

```
fourli-skills/
├── skills/                 # 核心 skills（每个 skill = SKILL.md + agents/openai.yaml）
│   ├── think/              #   需求澄清与共识摘要
│   ├── teacher/            #   中文技术调研讲解（禁止隐式触发）
│   ├── code-opt/           #   代码简化（不改行为）
│   ├── code-audit/         #   发布前代码风险审核（只报告不修改）
│   ├── checkpoint/        #   创建/查看/切换 checkpoint
│   └── checkpoint-maintenance/  #   维护已有 active checkpoint
├── hooks/                  # Codex 生命周期 hooks（可选增强层）
│   ├── hooks.json          #   注册 SessionStart / PreCompact / Stop
│   ├── session-start.sh    #   注入 active checkpoint 到 agent 上下文
│   ├── pre-compact.sh      #   compaction 前提醒
│   ├── stop.sh             #   stop 前提醒
│   └── emit-json.py        #   JSON 输出工具（所有 hook 共用）
├── .codex-plugin/          # Codex 插件元数据
├── .claude-plugin/         # Claude Code 插件元数据
├── assets/                 # logo / icon 资源
├── docs/
│   ├── CODE_WIKI.md        #   结构化代码百科（修改前必读）
│   └── superpowers/        #   历史设计稿与实施计划（仅供参考）
├── AGENTS.md               # 本文件
├── README.md               # 用户文档
└── package.json            # npm 包元数据
```

## 架构规则

- **单一职责**：每个 skill 只做一件事，不替代主工作流（superpowers）。
- **hooks 是增强，不是必需**：没有 hooks skills 也能工作。
- **POSIX 优先**：运行时脚本只用 `sh` + `awk` + `sed` + `grep`；仅 `emit-json.py` 使用 Python3。
- **分层严格**：`hooks/` 只放生命周期 wrapper，不放业务脚本；业务脚本放 `skills/<name>/scripts/`。
- **中英文分工**：agent-facing 的 description / 触发规则用英文；README、设计稿、checkpoint 模板中文为主。
- **PreCompact / Stop 不阻断用户流程**：输出必须走 `systemMessage` JSON，不能依赖普通 stdout。

## 编码约定

- Shell 脚本：`#!/bin/sh`，`set -u`，路径穿越防护（拒绝含 `/` 或 `..` 的 id）。
- SKILL.md：YAML frontmatter（`name` + `description`），正文用 Markdown。
- agents/openai.yaml：提供 `display_name`、`description`、可选 `policy` 配置。
- 新增 skill 时：在 `skills/<new-name>/` 下加 `SKILL.md` + `agents/openai.yaml`，并在 README.md skills 表格中登记。
- 新增 hook 时：在 `hooks/hooks.json` 里加条目，对应 `.sh` wrapper 通过 `emit-json.py` 输出。

## 关键常量

| 常量 | 值 |
| --- | --- |
| 注入区最大行数 | 60 |
| 注入区 markers | `<!-- fourli-checkpoint:inject-start -->` / `inject-end -->` |
| checkpoint-id 格式 | `<YYYY-MM-DD>-<任务名>[-<序号>]` |
| 用户项目运行时根 | `docs/checkpoints/` |
| active 指针文件 | `docs/checkpoints/.active_checkpoint` |
| 状态枚举 | `pending` / `in_progress` / `complete` |

## Skill 触发规则

| Skill | 显式/隐式 | 触发场景 |
| --- | --- | --- |
| `think` | 显式 | "先 think" / "grill" / "问透" / "澄清需求" |
| `teacher` | 显式（禁止隐式） | `$teacher` / "用 teacher 调研" |
| `code-opt` | 显式 | 代码能跑但难读难维护 |
| `code-audit` | 显式 | 发布前/合并前审核已改动代码风险 |
| `checkpoint` | 显式 | 创建/查看/切换 checkpoint |
| `checkpoint-maintenance` | 隐式 | 已有 active checkpoint + 阶段边界/接力风险/方向变更/完成 |

## 与 Superpowers 的关系

`fourli-skills` 与 superpowers 配合，不替代：

```text
think（可选，先澄清需求）→ brainstorming (sp) → writing-plans (sp) → implementation
                                                        ↓ (大任务时)
                                            checkpoint 创建一次 → maintenance 维护 → finish
```

`teacher` 和 `code-opt` 与上述流程正交，可独立调用。

## 敏感区域（修改前必读）

- 修改 checkpoint 脚本逻辑 → 先读 `docs/CODE_WIKI.md` 第五至七章
- 修改 hooks 输出协议 → 先读 `docs/CODE_WIKI.md` 第四章（含 `emit-json.py` 的 JSON schema）
- 新增 skill → 参考现有 skill 的 `SKILL.md` frontmatter 格式和 `agents/openai.yaml` 结构
- 历史设计稿 `docs/superpowers/specs/` 和 `plans/` 按**嵌套目录结构**讨论，已被当前扁平结构取代，不是事实来源

## 脚本测试（手动验证）

```bash
# checkpoint 创建
sh skills/checkpoint/scripts/init-checkpoint.sh "test-task"
# 查看 active
sh skills/checkpoint/scripts/set-active-checkpoint.sh
# 校验
sh skills/checkpoint-maintenance/scripts/validate-checkpoint.sh docs/checkpoints/<id>/checkpoint.md
# 关闭
sh skills/checkpoint-maintenance/scripts/finish-checkpoint.sh
```
