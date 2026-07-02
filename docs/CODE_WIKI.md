# Fourli Skills · Code Wiki

> 本文档是 `fourli-skills` 仓库的结构化代码百科，覆盖整体架构、模块职责、关键脚本、依赖关系、运行时数据结构与使用方式。
> 文档基线对应仓库当前文件状态，与历史 `docs/superpowers/specs|plans` 中的设计稿可能存在差异，以仓库现状为准。

---

## 一、项目概览

### 1.1 是什么

`fourli-skills` 是一个面向 AI 编码 agent（Codex / Trae / Claude / 其他兼容 skills 的 agent）的**可复用 skills 集合**，不是单一应用程序。它把作者常用的几类工作方式拆成独立 skill，让 agent 在合适的时机调用。

仓库同时也是一个 **Codex / Claude Code 插件包**（通过 `.codex-plugin/` 与 `.claude-plugin/` 元数据声明），并可选提供一组 **Codex hooks** 用于增强 checkpoint 接力体验。

### 1.2 解决什么问题

| 痛点 | 对应 skill |
| --- | --- |
| 需求模糊导致方向偏差、返工多 | `think` |
| agent 凭经验编、不查事实、英文术语看不懂 | `teacher` |
| 能跑但难读难维护的代码 | `code-opt` |
| 大任务跨窗口 / 跨 session 接力丢失上下文 | `checkpoint` + `checkpoint-maintenance` |

### 1.3 核心理念

- **单一职责**：每个 skill 只做一件事，不替代主工作流（如 superpowers）。
- **hook 是增强，不是必需**：没有 hooks 也能用，只是 checkpoint 维护更依赖目标项目的 `AGENTS.md` 约定。
- **POSIX 优先**：运行时脚本只用 `sh` + `awk` + `sed` + `grep`；仅在 hook 输出 JSON 时用 Python3。
- **中英文分工**：agent-facing 的 description / 触发规则用英文；README、设计稿、`checkpoint.md` 模板中文为主。

---

## 二、整体架构

### 2.1 分层

```text
┌──────────────────────────────────────────────────────────────┐
│  ① 插件元数据层                                                │
│     .claude-plugin/      Claude Code 插件清单 & marketplace   │
│     .codex-plugin/       Codex 插件清单（含 skills/hooks 入口） │
│     package.json         npm 包元数据（用于 npx skills 安装）   │
│     marketplace.json     Claude marketplace 注册项             │
├──────────────────────────────────────────────────────────────┤
│  ② Skills 层   skills/<skill-name>/                           │
│     SKILL.md             agent 提示词（核心，所有 skill 都有）  │
│     agents/openai.yaml   agent 接口元数据（display_name 等）   │
│     scripts/*.sh         运行时脚本（仅 checkpoint 系列有）   │
├──────────────────────────────────────────────────────────────┤
│  ③ Hooks 层   hooks/                                          │
│     hooks.json           注册 3 个 Codex 生命周期事件          │
│     session-start.sh     SessionStart 包装器                  │
│     pre-compact.sh       PreCompact 包装器                     │
│     stop.sh              Stop 包装器                          │
│     emit-json.py         JSON 输出工具（被三个 hook 共用）     │
├──────────────────────────────────────────────────────────────┤
│  ④ 资源与文档层                                                │
│     assets/              logo / icon                          │
│     docs/superpowers/    设计稿与实施计划（历史档案）          │
│     AGENTS.md            工作区规则与术语约定                  │
│     README.md            用户文档                             │
└──────────────────────────────────────────────────────────────┘
```

### 2.2 仓库目录树

```text
fourli-skills/
├── .claude-plugin/
│   ├── marketplace.json         # Claude Code marketplace 注册
│   └── plugin.json              # Claude Code 插件清单
├── .codex-plugin/
│   ├── icon.svg
│   └── plugin.json              # Codex 插件清单（指向 skills/ 与 hooks/）
├── assets/                      # 图标资源
├── docs/
│   ├── CODE_WIKI.md             # 本文档
│   └── superpowers/
│       ├── plans/               # 历史实施计划（已被仓库现状取代）
│       └── specs/               # 历史设计稿
├── hooks/                       # Codex 生命周期 hook（可选增强层）
│   ├── emit-json.py
│   ├── hooks.json
│   ├── pre-compact.sh
│   ├── session-start.sh
│   └── stop.sh
├── skills/                     # 核心 skills
│   ├── checkpoint/
│   │   ├── SKILL.md
│   │   ├── agents/openai.yaml
│   │   └── scripts/
│   │       ├── init-checkpoint.sh
│   │       └── set-active-checkpoint.sh
│   ├── checkpoint-maintenance/
│   │   ├── SKILL.md
│   │   ├── agents/openai.yaml
│   │   └── scripts/
│   │       ├── extract-inject-block.sh
│   │       ├── finish-checkpoint.sh
│   │       ├── resolve-checkpoint.sh
│   │       └── validate-checkpoint.sh
│   ├── code-opt/
│   │   ├── SKILL.md
│   │   └── agents/openai.yaml
│   ├── teacher/
│   │   ├── SKILL.md
│   │   └── agents/openai.yaml
│   └── think/
│       ├── SKILL.md
│       └── agents/openai.yaml
├── AGENTS.md                    # 工作区规则（含术语：sp = superpowers）
├── README.md
└── package.json
```

### 2.3 调用拓扑

```text
用户 ──触发 skill──▶ SKILL.md 提示词 ──告诉 agent──▶ 调用 scripts/*.sh

Codex 生命周期事件 ──▶ hooks/hooks.json ──▶ *.sh
                                            │
                                            ├─ 调用 resolve-checkpoint.sh
                                            ├─ 调用 extract-inject-block.sh
                                            └─ 调用 emit-json.py ──▶ stdout JSON
```

---

## 三、Skills 模块详解

每个 skill 的标准结构是 `SKILL.md`（agent 提示词，frontmatter 含 `name` + `description`）+ `agents/openai.yaml`（agent 接口元数据）。仅 checkpoint 系列额外带 shell 脚本。

### 3.1 `think` · 需求审问

- **文件**：[skills/think/SKILL.md](file:///Users/fourli/Desktop/app/fourli-skills/skills/think/SKILL.md)
- **触发**：需求模糊、用户要求"先想清楚""问透""grill spec"，或已有 draft spec/design 需要被审问。
- **不做**：写代码、写实现方案、写 implementation plan。
- **两种模式**：
  - `intent-intake`：初始需求太模糊时做最短意图澄清，问到能进入 brainstorming 即停。
  - `spec-grill`：已有草案后审问"文档里的具体主张"，按目标一致性 → 范围/非目标 → Always/Ask first/Never → 状态和分支 → 失败路径 → 验收标准 → 风险假设 顺序检查。
- **提问规则**：一次只问一个问题；先列最多 3 个高风险缺口再问第一个；优先给选项。
- **与 superpowers 衔接**：`intent-intake → superpowers:brainstorming → spec-grill → 写回 spec → superpowers:writing-plans`。`think` 不重复 brainstorming 已会问的问题。
- **YAML 配置**：[skills/think/agents/openai.yaml](file:///Users/fourli/Desktop/app/fourli-skills/skills/think/agents/openai.yaml) 提供 `fourli:think` 显示名与默认 prompt。

### 3.2 `teacher` · 中文技术调研老师

- **文件**：[skills/teacher/SKILL.md](file:///Users/fourli/Desktop/app/fourli-skills/skills/teacher/SKILL.md)
- **触发**：用户显式调用 `$teacher` / `teacher`，或要求"用 teacher 调研/讲解"。
- **核心原则**：
  - 先查事实，再讲解；不凭经验编。
  - 默认主动联网搜索；当前工作目录不是默认资料源，除非用户明确给本地路径。
  - 区分事实和判断；推断明确写"我的判断是"。
  - 资料不足直接说"不确定"。
  - 默认中文；英文术语补大白话解释。
- **调研入口判断**：URL / `owner/repo` / 产品名 / 概念 / 本地路径，分别走不同的来源优先级。
- **调研深度三档**：快速（2-4 来源）/ 深度（多来源交叉验证，至少两类证据）/ 超深（派 2-4 个 fresh subagent 并行调研）。
- **来源优先级**：官方 > 代码 > 项目讨论 > 学术 > 工程社区 > 新闻社交媒体。
- **回答结构**（按复杂度裁剪）：一句话结论 → 大白话 → 术语 → 事实依据 → 小白视角 → 工程师视角 → 架构师视角 → 学习路径。
- **YAML 特殊配置**：`policy.allow_implicit_invocation: false`——**禁止隐式触发**，必须显式调用。

### 3.3 `code-opt` · 代码简化

- **文件**：[skills/code-opt/SKILL.md](file:///Users/fourli/Desktop/app/fourli-skills/skills/code-opt/SKILL.md)
- **触发**：代码能工作但难读难维护；code review 时被指出复杂度问题；合并引入重复或风格不一致。
- **不做**：代码已经干净就别为简化而简化；不懂就先别动；性能敏感场景慎重；准备整体重写的模块别花精力简化。
- **五大原则**：
  1. **行为完全保留**——只改表达方式，不改输入输出/副作用/错误行为/边界。
  2. **遵循项目约定**——参考 `CLAUDE.md` / `AGENTS.md` 和邻近代码风格。
  3. **清晰优先于聪明**——explicit > compact。
  4. **维持平衡**——警惕过度内联、合并无关逻辑、删除必要抽象、追求行数。
  5. **只动改动过的范围**——避免 drive-by refactor。
- **四步流程**：先理解再动手（Chesterton's Fence）→ 识别简化机会（结构/命名/冗余三类信号表）→ 增量改、改一次跑一次测试 → 验证整体。
- **500 行规则**：超过 500 行的改动用 codemod / AST 自动化，不要手工改。
- **语言指引**：附带 TypeScript / Python / React 的具体简化示例。
- **来源**：改编自 Claude Code 官方 Simplifier 插件，做成 model-agnostic 的 skill。

### 3.4 `checkpoint` · 创建/查看/切换 checkpoint

- **文件**：[skills/checkpoint/SKILL.md](file:///Users/fourli/Desktop/app/fourli-skills/skills/checkpoint/SKILL.md)
- **触发**：用户**显式**要求创建、查看或切换 checkpoint 时才用。
- **职责**：
  - 创建 `docs/checkpoints/<id>/checkpoint.md` 并写入 `.active_checkpoint`。
  - 切换当前 active checkpoint。
  - 查看 active checkpoint。
- **约束**：
  - 阶段地图允许粗糙、不完整。
  - 只要求有总目标 + 至少一个可开始的粗阶段。
  - 不为完善阶段地图持续追问。
  - 不启动主工作流、不写 implementation plan、不追踪执行进度。
- **运行时脚本**：见 [§五-1](#五1-checkpoint-系列脚本)。

### 3.5 `checkpoint-maintenance` · 维护已有 checkpoint

- **文件**：[skills/checkpoint-maintenance/SKILL.md](file:///Users/fourli/Desktop/app/fourli-skills/skills/checkpoint-maintenance/SKILL.md)
- **触发条件（必须满足"已有 active checkpoint"）**：
  - session start / resume 需要恢复方向；
  - 阶段边界到达；
  - 上下文接力风险；
  - 方向变更影响阶段地图；
  - compact / stop 接力时刻；
  - 大任务整体完成需要关闭。
- **不做**：不因普通执行进度更新；不创建/修改主工作流的 spec / plan / checklist / 验证记录；不写执行日志。
- **读取规则**：默认只读 `<!-- fourli-checkpoint:inject-start --> ... inject-end -->` 之间的注入区；只有更新方向变更、关键证据、收尾记录、关闭或修复定界符时才读完整文件。
- **运行时脚本**：见 [§五-2](#五2-checkpoint-maintenance-系列脚本)。

---

## 四、Hooks 系统详解

### 4.1 注册表 [hooks/hooks.json](file:///Users/fourli/Desktop/app/fourli-skills/hooks/hooks.json)

| 事件 | matcher | 命令 | statusMessage | timeout |
| --- | --- | --- | --- | --- |
| `SessionStart` | `startup\|resume\|clear\|compact` | `sh ${PLUGIN_ROOT}/hooks/session-start.sh` | Loading checkpoint | — |
| `PreCompact` | `*` | `sh ${PLUGIN_ROOT}/hooks/pre-compact.sh` | Checking checkpoint handoff | — |
| `Stop` | — | `sh ${PLUGIN_ROOT}/hooks/stop.sh` | Checking checkpoint handoff | 10s |

### 4.2 三个 hook 的工作流程

```text
事件触发
  │
  ▼
调用 resolve-checkpoint.sh 解析 active checkpoint
  │
  ├─ 无 active checkpoint ─▶ exit 0（静默，无输出）
  │
  └─ 有 active checkpoint
        │
        ▼
   ┌────────────────┬─────────────────┐
   │ SessionStart   │ PreCompact/Stop │
   └──────┬─────────┴──────┬──────────┘
          ▼                ▼
   extract-inject-block    直接拼字符串
   .sh 提取注入区
          │                │
          └───┬────────────┘
              ▼
       通过 stdin 传给 emit-json.py
              │
              ▼
   additionalContext（SessionStart）
   或 systemMessage（PreCompact/Stop）
              │
              ▼
       stdout 输出 JSON 给 Codex
```

### 4.3 输出协议

`emit-json.py` 接收 `<event-name>` 与 `<mode>` 两个参数，从 stdin 读消息，按模式产出：

- `additionalContext` 模式：包装成 `{ "continue": true, "hookSpecificOutput": { "hookEventName": ..., "additionalContext": ... } }`——用于 `SessionStart`，把注入区塞进 agent 上下文。
- `systemMessage` 模式：包装成 `{ "continue": true, "systemMessage": ... }`——用于 `PreCompact` / `Stop`，仅做非阻断提醒。
- `PreCompact` 与 `Stop` **不阻断用户流程**，不依赖普通 stdout（普通 stdout 在这些事件里会被忽略）。

### 4.4 注入区结构

`SessionStart` 注入的 `additionalContext` 长这样：

```text
[fourli-checkpoint]
role: checkpoint handoff only
checkpoint: <checkpoint-id>
rules:
- checkpoint.md is a handoff index, not a requirements design, implementation plan, execution log, or verification record.
- Read the delimited block for orientation; read the full file only when maintenance is needed.
===BEGIN FOURLI CHECKPOINT===
<inject-block 60 行以内的内容>
===END FOURLI CHECKPOINT===
```

如果 inject 定界符损坏，`SessionStart` 会改为注入一条"需要修复定界符"的提示，仍然走 `additionalContext`，不让 hook 失败。

---

## 五、关键脚本说明

### 5.1 `checkpoint` 系列脚本

#### 5.1.1 [init-checkpoint.sh](file:///Users/fourli/Desktop/app/fourli-skills/skills/checkpoint/scripts/init-checkpoint.sh)

**用途**：在用户项目里创建一个新 checkpoint。

**调用**：`sh <fourli-skills-root>/skills/checkpoint/scripts/init-checkpoint.sh "任务名"`

**逻辑**：
1. 校验任务名（去首尾空白；拒绝包含 `/` 或 `..` 的名字，防路径穿越）。
2. `checkpoint-id = <YYYY-MM-DD>-<任务名>`；如果已存在则追加 `-2`、`-3`...
3. 在用户项目的 `docs/checkpoints/<checkpoint-id>/` 下生成 `checkpoint.md`，模板包含：
   - 注入区（`inject-start` / `inject-end` 之间）：`# id`、`## 总目标`、`## 边界`、`## 阶段地图`（默认一行 P1）、`## 当前接力`。
   - 历史区：`## 方向变更`、`## 关键证据`、`## 收尾记录`。
4. 把 checkpoint-id 写入 `docs/checkpoints/.active_checkpoint`。
5. stdout 报告创建的文件路径与 active id。

**退出码**：`0` 成功；`2` 名字为空或非法。

#### 5.1.2 [set-active-checkpoint.sh](file:///Users/fourli/Desktop/app/fourli-skills/skills/checkpoint/scripts/set-active-checkpoint.sh)

**用途**：切换或查看当前 active checkpoint。

**调用**：
- 查看当前：`sh set-active-checkpoint.sh`
- 切换：`sh set-active-checkpoint.sh <checkpoint-id>`

**逻辑**：
- 无参数：读 `.active_checkpoint`，如果 id 对应的 `checkpoint.md` 存在就打印 `Active checkpoint: ...` 与 `Path: ...`；否则提示 `No valid active checkpoint.`
- 有参数：拒绝含 `/` 或 `..` 的 id；校验 `docs/checkpoints/<id>/checkpoint.md` 存在；写 `.active_checkpoint`。

**退出码**：`0` 成功或仅查看；`1` 找不到 checkpoint；`2` 非法 id。

### 5.2 `checkpoint-maintenance` 系列脚本

#### 5.2.1 [resolve-checkpoint.sh](file:///Users/fourli/Desktop/app/fourli-skills/skills/checkpoint-maintenance/scripts/resolve-checkpoint.sh)

**用途**：解析当前 active checkpoint 的 `checkpoint.md` 绝对路径。是 hooks 与其他维护脚本的基础组件。

**调用**：`sh resolve-checkpoint.sh`（也可通过环境变量 `CHECKPOINT_ID` 指定）

**逻辑**：
1. 如果 `docs/checkpoints/` 不存在，直接 `exit 0`。
2. 解析 id：环境变量 `CHECKPOINT_ID` > `.active_checkpoint` 文件内容。两端做 `trim`。
3. `valid_id` 拒绝空、含 `/` 或 `..` 的 id。
4. 校验 `docs/checkpoints/<id>/checkpoint.md` 存在。
5. **路径穿越防护**：`within_checkpoint_root` 用 `realpath`（或 python3 兜底）做真实路径规范化，确认解析后的路径仍位于 `docs/checkpoints/` 之下。
6. stdout 输出 `checkpoint.md` 的路径。

**关键设计**：任何环节失败都 `exit 0` 静默退出——hook 调用方依赖"无输出 = 无 active checkpoint"的语义。

#### 5.2.2 [extract-inject-block.sh](file:///Users/fourli/Desktop/app/fourli-skills/skills/checkpoint-maintenance/scripts/extract-inject-block.sh)

**用途**：从 `checkpoint.md` 中提取 `inject-start` 与 `inject-end` 之间的内容，并限制在 60 行以内。

**调用**：`sh extract-inject-block.sh <checkpoint.md 路径>`

**逻辑**（awk 实现）：
- 遇到 `inject-start`：进入块、跳过 marker 行。
- 遇到 `inject-end`：退出。
- 块内打印，但只打印前 60 行。
- `END` 块：
  - 没看到 start 或 end → `exit 2`（定界符缺失）。
  - 实际行数 > 60 → `exit 3`（超长）。

**退出码**：`0` 成功；`1` 文件不存在；`2` 定界符缺失；`3` 超过 60 行。

#### 5.2.3 [validate-checkpoint.sh](file:///Users/fourli/Desktop/app/fourli-skills/skills/checkpoint-maintenance/scripts/validate-checkpoint.sh)

**用途**：校验 `checkpoint.md` 的定界符结构是否合法。

**调用**：`sh validate-checkpoint.sh <checkpoint.md 路径>`

**逻辑**：
1. 用 `grep -c` 检查 `inject-start` 与 `inject-end` 各出现**恰好一次**。
2. 调 `extract-inject-block.sh` 复检注入区不超过 60 行。
3. 通过则打印 `[fourli-checkpoint] checkpoint OK`。

**退出码**：`0` OK；`1` 文件不存在；`2` start 不是恰好一次；`3` end 不是恰好一次；`4` 注入区超长或无法提取。

#### 5.2.4 [finish-checkpoint.sh](file:///Users/fourli/Desktop/app/fourli-skills/skills/checkpoint-maintenance/scripts/finish-checkpoint.sh)

**用途**：任务完成后关闭 active checkpoint。

**调用**：`sh finish-checkpoint.sh [checkpoint-id]`（不传则用 `.active_checkpoint`）

**逻辑**：
1. 解析 id（参数或 `.active_checkpoint`）；空则提示"无 active checkpoint"并 `exit 0`。
2. 拒绝非法 id。
3. 校验 `checkpoint.md` 存在。
4. **先调 `validate-checkpoint.sh`**，定界符结构坏了就拒绝关闭，提示需要先修复。
5. 校验通过后，仅删除 `.active_checkpoint`（保留历史 `checkpoint.md` 不删）。
6. stdout 报告清理结果。

**关键设计**：历史 checkpoint 文件**保留**，只清掉 `.active_checkpoint` 指针，方便事后追溯。

### 5.3 hooks 脚本

#### 5.3.1 [session-start.sh](file:///Users/fourli/Desktop/app/fourli-skills/hooks/session-start.sh)

**触发**：`SessionStart` 事件（startup / resume / clear / compact）。

**逻辑**：
1. 用 `${PLUGIN_ROOT}` 定位仓库根；兜底用脚本自身相对路径。
2. 调 `resolve-checkpoint.sh` 拿到 active `checkpoint.md`。
3. 调 `extract-inject-block.sh` 提取注入区。
   - 提取失败（定界符坏）→ 注入"需要修复"提示，仍走 `additionalContext`。
   - 提取成功 → 用 heredoc 拼出 `[fourli-checkpoint]` 元信息 + 规则 + `===BEGIN/END FOURLI CHECKPOINT===` 包住的注入区。
4. 通过 stdin 传给 `emit-json.py SessionStart additionalContext`，stdout 即最终 JSON。

#### 5.3.2 [pre-compact.sh](file:///Users/fourli/Desktop/app/fourli-skills/hooks/pre-compact.sh)

**触发**：`PreCompact` 事件（matcher `*`）。

**逻辑**：解析 active checkpoint；如果存在，就拼一段简短提醒（"compaction 前只在阶段边界/方向变更/接力风险/任务完成时更新"），通过 `emit-json.py PreCompact systemMessage` 输出。

#### 5.3.3 [stop.sh](file:///Users/fourli/Desktop/app/fourli-skills/hooks/stop.sh)

**触发**：`Stop` 事件（无 matcher）。

**逻辑**：与 `pre-compact.sh` 类似，提醒内容多了"如果整体任务完成，跑 `finish-checkpoint.sh` 清掉 active checkpoint"。timeout 10 秒。

### 5.4 hooks 共用工具

#### 5.4.1 [emit-json.py](file:///Users/fourli/Desktop/app/fourli-skills/hooks/emit-json.py)

**用途**：把任意 stdin 文本包装成合法的 Codex hook JSON。

**调用**：`python3 emit-json.py <event-name> <mode>`，从 stdin 读消息。

**两种 mode**：
- `additionalContext`：包装成 `hookSpecificOutput.additionalContext`（SessionStart 用，注入到 agent 上下文）。
- `systemMessage`：包装成顶层 `systemMessage`（PreCompact / Stop 用，仅提醒）。

**为什么用 Python**：Codex hook 输出必须是合法 JSON；shell 拼 JSON 容易踩转义坑，Python3 标准库 `json.dumps(ensure_ascii=False)` 是最稳的方式。这是整个仓库**唯一**的 Python 依赖点。

---

## 六、依赖关系

### 6.1 内部依赖

```text
hooks/session-start.sh ──┐
hooks/pre-compact.sh    ──┼──▶ resolve-checkpoint.sh
hooks/stop.sh           ──┤
                        │  └──▶ (仅 session-start) extract-inject-block.sh
                        ▼
                  hooks/emit-json.py
                        ▲
                        │
hooks/finish-checkpoint.sh ─▶ validate-checkpoint.sh ─▶ extract-inject-block.sh
```

- 三个 hook 都依赖 `resolve-checkpoint.sh`。
- `session-start.sh` 额外依赖 `extract-inject-block.sh`。
- `finish-checkpoint.sh` 依赖 `validate-checkpoint.sh`，后者再依赖 `extract-inject-block.sh`。
- 所有 hook 共用 `emit-json.py`。
- `init-checkpoint.sh` 与 `set-active-checkpoint.sh` 是用户入口，**不依赖** maintenance 脚本。

### 6.2 外部依赖

| 依赖 | 用途 | 是否必需 |
| --- | --- | --- |
| POSIX `sh` | 所有运行时脚本 | 必需 |
| `awk` | `extract-inject-block.sh` 提取注入区 | 必需 |
| `sed` / `grep` / `mkdir` / `cat` / `basename` / `wc` / `tr` / `rm` | 各脚本常规操作 | 必需（macOS / Linux 默认自带） |
| `realpath` | `resolve-checkpoint.sh` 路径规范化 | 可选，缺失时 fallback 到 `python3` |
| `python3` | `emit-json.py` 与 `realpath` fallback | 仅 hooks 必需；纯 skills 模式可缺 |
| `superpowers` skills | `think` 与 checkpoint 的衔接对象 | 可选，缺失时由其他主工作流替代 |

### 6.3 与 superpowers 的关系

`fourli-skills` **不替代** superpowers，而是与之配合：

| 关注点 | 谁负责 |
| --- | --- |
| 意图澄清、spec 审问 | `fourli:think` |
| 把需求发展成设计草案 | `superpowers:brainstorming` |
| 拆解实施步骤 | `superpowers:writing-plans` |
| 执行与验证 | superpowers execution / verification |
| 大任务接力状态记录 | `fourli:checkpoint` + `checkpoint-maintenance` |

checkpoint **绝不**复制 superpowers 的 spec / plan / execution / verification 内容；它只是一个接力索引，指向主工作流该看的入口。

### 6.4 skill 之间的隐式顺序

```text
intent-intake (think)
  → superpowers:brainstorming 产出 draft spec
  → spec-grill (think) 审问草案
  → 写回 spec
  → superpowers:writing-plans
  → implementation（如规模大）
      → checkpoint 创建一次
      → checkpoint-maintenance 在阶段边界维护
      → 完成时 finish-checkpoint
```

`teacher` 与 `code-opt` 与上述流程**正交**，可独立调用。

---

## 七、运行时数据结构

### 7.1 用户项目里的运行时目录

用户安装并使用 `fourli-skills` 后，会在**用户自己的项目根**下生成（不在本仓库内）：

```text
<user-project>/
└── docs/
    └── checkpoints/
        ├── .active_checkpoint          # 当前 active 的 checkpoint-id（单行文本）
        ├── 2026-06-28-i18n/
        │   └── checkpoint.md
        └── 2026-07-03-auth/
            └── checkpoint.md
```

- `.active_checkpoint` 是普通文本文件，单行存 `<checkpoint-id>`。
- 历史 checkpoint 即使被 finish 也会保留 `checkpoint.md`，只删 `.active_checkpoint`。

### 7.2 `checkpoint.md` 结构

文件分为**注入区**（marker 包住，最多 60 行）和**历史区**（marker 外）：

```markdown
<!-- fourli-checkpoint:inject-start -->

# <checkpoint-id>

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
- 当前阶段：
- 下一步：
- 最近完成：
- 注意事项：
- 继续前必须看：

<!-- fourli-checkpoint:inject-end -->

## 方向变更
-

## 关键证据
-

## 收尾记录
-
```

### 7.3 设计约束

| 约束 | 取值 | 出处 |
| --- | --- | --- |
| 注入区最大行数 | 60 | `extract-inject-block.sh`、`validate-checkpoint.sh` |
| 状态值枚举 | `pending` / `in_progress` / `complete` | 设计稿 |
| `.active_checkpoint` 解析规则 | 只读显式 id 或文件内容，**不** fallback 到最新目录 | 设计稿验收标准 |
| finish 行为 | 删 `.active_checkpoint`，保留 `checkpoint.md` | `finish-checkpoint.sh` |
| `PreCompact` / `Stop` 是否阻断 | 不阻断（`continue: true`） | `emit-json.py` |
| checkpoint-id 格式 | `<YYYY-MM-DD>-<任务名>`，重名追加 `-2`/`-3` | `init-checkpoint.sh` |
| 安全校验 | 拒绝 id / 任务名含 `/` 或 `..`；解析时做 `realpath` 路径穿越防护 | 所有接受 id 的脚本 |

---

## 八、安装与运行方式

本仓库**本身不需要运行**——它是 skills 包，目标是把 `skills/` 暴露给 agent。三种安装方式：

### 8.1 作为 Codex 插件

```bash
codex plugin marketplace add four-li/skills
```

启用后 `~/.codex/config.toml` 通常会出现：

```toml
[plugins."fourli-skills@fourli"]
enabled = true
```

Codex 会按 `.codex-plugin/plugin.json` 中的声明加载：
- `"skills": "./skills/"` → 加载 5 个 skill
- `"hooks": "./hooks/hooks.json"` → 注册 3 个生命周期 hook
- `"interface.capabilities": ["Read", "Write"]` → 申请文件读写权限

### 8.2 通过 npx skills（推荐用于 Trae / 多 agent）

```bash
# 全局安装给 trae-cn
npx skills add four-li/skills --agent trae-cn -g -y

# 后续只更新这套 skills
npx skills update -g think teacher code-opt checkpoint checkpoint-maintenance
```

### 8.3 其他兼容 skills 的 agent

直接读取仓库根目录的 `skills/`。如果目标 agent 不支持 hooks，**只用 skills 也能工作**，只是 `checkpoint-maintenance` 的触发更依赖目标项目 `AGENTS.md` 里的提示词。

### 8.4 不支持 hooks 时的退化方案

把以下提示词加入目标项目的 `AGENTS.md`：

```markdown
## Fourli Checkpoint

If `docs/checkpoints/.active_checkpoint` exists, use `checkpoint-maintenance` only at session start/resume, phase boundaries, context handoff risk, direction changes, or task closeout.

For orientation, read only the delimited checkpoint inject block first. Read the full `checkpoint.md` only when updating direction changes, key evidence, closeout notes, closing the checkpoint, or repairing the checkpoint file.

Do not use checkpoint content as an implementation plan. The primary workflow owns requirements design, implementation planning, execution, and verification.
```

### 8.5 典型使用流程

```bash
# 1. 在用户项目根目录创建一个大任务 checkpoint
sh <skills-root>/skills/checkpoint/scripts/init-checkpoint.sh "i18n"

# 2. 查看当前 active
sh <skills-root>/skills/checkpoint/scripts/set-active-checkpoint.sh

# 3. 阶段边界或方向变更时，agent 用 checkpoint-maintenance 维护
sh <skills-root>/skills/checkpoint-maintenance/scripts/validate-checkpoint.sh docs/checkpoints/<id>/checkpoint.md

# 4. 任务整体完成
sh <skills-root>/skills/checkpoint-maintenance/scripts/finish-checkpoint.sh
```

如果安装了 hooks，上述 1、4 步外的"维护时机提醒"会由 `SessionStart` / `PreCompact` / `Stop` 自动注入到 agent 上下文。

---

## 九、扩展点与边界

### 9.1 checkpoint 的明确边界

| checkpoint **是** | checkpoint **不是** |
| --- | --- |
| 大任务接力状态索引 | 需求设计 |
| 阶段地图（粗粒度） | implementation plan |
| 方向变更记录 | 执行日志 |
| 关键证据（影响后续判断的） | 验证记录 |
| 主工作流入口指针 | superpowers spec / plan 的副本 |

### 9.2 可安全扩展的方向

- **新增 skill**：在 `skills/<new-skill>/` 下加 `SKILL.md` + `agents/openai.yaml`，并在根 `README.md` 的 skills 表格里登记。
- **新增 hook 事件**：在 `hooks/hooks.json` 里加事件条目，对应 `.sh` wrapper 调用现有脚本并通过 `emit-json.py` 输出。
- **新增运行时脚本**：放进对应 skill 的 `scripts/` 下，不要塞到 `hooks/`。

### 9.3 不要做的事

- 不要在 `hooks/` 下放业务运行时脚本——`hooks/` 只放生命周期 wrapper。
- 不要让 `PreCompact` / `Stop` 默认阻断用户流程。
- 不要让 hook 依赖普通 stdout——`PreCompact` / `Stop` 的普通 stdout 会被 Codex 忽略，必须走 `systemMessage`。
- 不要在 checkpoint 里堆细实现步骤。
- 不要为了"完善阶段地图"持续追问用户。
- 不要让 `init-checkpoint.sh` 接受含 `/` 或 `..` 的任务名（路径穿越防护）。

### 9.4 与历史设计稿的关系

`docs/superpowers/specs/2026-06-28-fourli-checkpoint-design.md` 与 `docs/superpowers/plans/2026-06-28-fourli-checkpoint-implementation.md` 是 checkpoint 的设计与实施档案。两份文档最初按嵌套 `.codex-plugins/fourli-checkpoint/` 目录结构讨论，**仓库已修正为根目录扁平结构**（`.codex-plugin/` + `skills/` + `hooks/`）。这两份历史文档不是当前文件布局的事实来源，**以仓库现状为准**。

---

## 十、速查表

### 10.1 skill 触发条件速查

| Skill | 触发关键词 / 场景 | 是否需显式调用 |
| --- | --- | --- |
| `think` | "先 think""grill""问透""需求做透""审一下 spec" | 是 |
| `teacher` | `$teacher` / `teacher` / "用 teacher 调研" | 是（`allow_implicit_invocation: false`） |
| `code-opt` | 代码能跑但难读难维护；review 被指出复杂度 | 是 |
| `checkpoint` | "创建 checkpoint""查看""切换" | 是 |
| `checkpoint-maintenance` | 已有 active + 阶段边界 / 接力风险 / 方向变更 / 完成 | 否（agent 自主判断） |

### 10.2 脚本退出码速查

| 脚本 | 0 | 1 | 2 | 3 | 4 |
| --- | --- | --- | --- | --- | --- |
| `init-checkpoint.sh` | 创建成功 | — | 名字为空或非法 | — | — |
| `set-active-checkpoint.sh` | 查看或切换成功 | checkpoint 不存在 | 非法 id | — | — |
| `resolve-checkpoint.sh` | 解析成功（或静默无输出） | — | — | — | — |
| `extract-inject-block.sh` | 提取成功 | 文件不存在 | 定界符缺失 | 注入区超 60 行 | — |
| `validate-checkpoint.sh` | 校验通过 | 文件不存在 | start 不是恰好一次 | end 不是恰好一次 | 注入区超长 |
| `finish-checkpoint.sh` | 关闭成功 | checkpoint 不存在或校验失败 | 非法 id | — | — |

### 10.3 关键常量

| 常量 | 值 | 位置 |
| --- | --- | --- |
| 注入区最大行数 | `60` | `extract-inject-block.sh`、`validate-checkpoint.sh` |
| 注入区起始 marker | `<!-- fourli-checkpoint:inject-start -->` | `init-checkpoint.sh`、`extract-inject-block.sh`、`validate-checkpoint.sh` |
| 注入区结束 marker | `<!-- fourli-checkpoint:inject-end -->` | 同上 |
| 状态枚举 | `pending` / `in_progress` / `complete` | 设计稿、`checkpoint.md` 模板 |
| checkpoint-id 格式 | `<YYYY-MM-DD>-<任务名>[-<序号>]` | `init-checkpoint.sh` |
| 用户项目运行时根 | `docs/checkpoints/` | 所有脚本 |
| active 指针文件 | `docs/checkpoints/.active_checkpoint` | 所有脚本 |
| Stop hook 超时 | `10` 秒 | `hooks.json` |
