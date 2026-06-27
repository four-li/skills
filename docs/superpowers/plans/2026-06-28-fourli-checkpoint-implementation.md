# Fourli Checkpoint Implementation Plan

> Superseded note: This plan originally targeted a nested `.codex-plugins/fourli-checkpoint/` layout. The repository has since been corrected to a root package layout with `.codex-plugin/`, `skills/`, and `hooks/`. Do not use this plan as the current file layout source of truth.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `fourli-planning` with `fourli-checkpoint`, using a lightweight checkpoint file for large-task handoff without replacing the primary workflow.

**Architecture:** The plugin exposes two skills: `fourli/checkpoint` for user-triggered create/view/switch operations, and `fourli/checkpoint-maintenance` for agent-triggered upkeep of an existing active checkpoint. Runtime scripts live under the relevant skill directory; Codex hooks are thin wrappers that call those scripts and emit valid hook JSON.

**Tech Stack:** POSIX shell scripts, Python 3 only for JSON escaping in hook output, Codex plugin metadata, Markdown skills and docs.

## Global Constraints

- Do not keep compatibility with `docs/planning/`, `.active_plan`, `overview.md`, or `fourli-planning`.
- Do not create a deprecated alias for the old skill or plugin.
- Do not use checkpoint content as an implementation plan, execution log, or verification record.
- Keep injected checkpoint context inside `<!-- fourli-checkpoint:inject-start -->` and `<!-- fourli-checkpoint:inject-end -->`, with a 60-line maximum.
- `PreCompact` and `Stop` must emit JSON, not plain text.
- `Stop` and `PreCompact` must not block by default.
- Status values are exactly `pending`, `in_progress`, and `complete`.
- Agent-facing skill descriptions and hard rules use English; README and checkpoint template can use Chinese.

---

## File Structure

- Create `.codex-plugins/fourli-checkpoint/.codex-plugin/plugin.json` as the new Codex plugin manifest.
- Create `.codex-plugins/fourli-checkpoint/README.md` as the plugin-level user documentation.
- Create `.codex-plugins/fourli-checkpoint/skills/fourli/checkpoint/SKILL.md` for explicit user-triggered checkpoint creation, inspection, and switching.
- Create `.codex-plugins/fourli-checkpoint/skills/fourli/checkpoint/scripts/init-checkpoint.sh` and `set-active-checkpoint.sh` for user-facing runtime actions.
- Create `.codex-plugins/fourli-checkpoint/skills/fourli/checkpoint-maintenance/SKILL.md` for agent-facing maintenance triggers.
- Create `.codex-plugins/fourli-checkpoint/skills/fourli/checkpoint-maintenance/scripts/resolve-checkpoint.sh`, `extract-inject-block.sh`, `validate-checkpoint.sh`, and `finish-checkpoint.sh`.
- Create `.codex-plugins/fourli-checkpoint/hooks/hooks.json`, `session-start.sh`, `pre-compact.sh`, `stop.sh`, and `emit-json.py`.
- Modify root `marketplace.json` and `README.md`.
- Delete tracked `plugins/fourli-planning/` and untracked `.codex-plugins/fourli-planning/`.

### Task 1: Rename Plugin Shell And Metadata

**Files:**
- Create: `.codex-plugins/fourli-checkpoint/.codex-plugin/plugin.json`
- Create: `.codex-plugins/fourli-checkpoint/README.md`
- Modify: `marketplace.json`
- Modify: `README.md`
- Delete: `plugins/fourli-planning/`
- Delete: `.codex-plugins/fourli-planning/`

**Interfaces:**
- Produces: installed plugin name `fourli-checkpoint`
- Produces: plugin skills loaded from `.codex-plugins/fourli-checkpoint/skills/`
- Produces: plugin hooks loaded from `.codex-plugins/fourli-checkpoint/hooks/hooks.json`

- [ ] **Step 1: Create the new plugin directory**

Run:

```bash
mkdir -p .codex-plugins/fourli-checkpoint/.codex-plugin
mkdir -p .codex-plugins/fourli-checkpoint/hooks
mkdir -p .codex-plugins/fourli-checkpoint/skills/fourli/checkpoint/scripts
mkdir -p .codex-plugins/fourli-checkpoint/skills/fourli/checkpoint-maintenance/scripts
```

Expected: directories exist.

- [ ] **Step 2: Replace plugin manifest**

Create `.codex-plugins/fourli-checkpoint/.codex-plugin/plugin.json`:

```json
{
  "name": "fourli-checkpoint",
  "version": "0.1.0",
  "description": "Lightweight task checkpoint handoff for large workflows.",
  "author": {
    "name": "fourli",
    "url": "https://github.com/fourli"
  },
  "repository": "https://github.com/fourli/fourli-skills",
  "license": "MIT",
  "keywords": [
    "checkpoint",
    "handoff",
    "workflow",
    "superpowers"
  ],
  "skills": "./skills/",
  "hooks": "./hooks/hooks.json",
  "interface": {
    "displayName": "Fourli Checkpoint",
    "shortDescription": "Lightweight checkpoint handoff for large tasks",
    "longDescription": "fourli-checkpoint keeps one docs/checkpoints checkpoint per large task. It records handoff state only and does not replace the primary workflow for requirements design, implementation planning, execution, or verification.",
    "developerName": "fourli",
    "category": "Productivity",
    "capabilities": [
      "Read",
      "Write"
    ],
    "defaultPrompt": [
      "Create a lightweight checkpoint.",
      "Show the current active checkpoint."
    ]
  }
}
```

- [ ] **Step 3: Replace root marketplace**

Set `marketplace.json` to:

```json
{
  "name": "fourli-skills",
  "interface": {
    "displayName": "Fourli Skills"
  },
  "plugins": [
    {
      "name": "fourli-checkpoint",
      "source": {
        "source": "local",
        "path": "./.codex-plugins/fourli-checkpoint"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Productivity"
    }
  ]
}
```

- [ ] **Step 4: Replace root README**

Set `README.md` to:

```markdown
# Fourli Skills Plugins

## 当前支持

- `fourli-checkpoint`：为大任务维护轻量 checkpoint 接力文件的 Codex 插件。

## 安装

```bash
codex plugin marketplace add /path/to/fourli-skills
```

## 说明

- 仓库通过 `marketplace.json` 暴露 `fourli-checkpoint`。
- `fourli-checkpoint` 使用 `.codex-plugins/fourli-checkpoint`。
- checkpoint 只记录大任务接力状态，不替代主工作流的需求设计、实现计划、执行和验证。
```

- [ ] **Step 5: Create plugin README**

Create `.codex-plugins/fourli-checkpoint/README.md`:

```markdown
# fourli-checkpoint

为大任务提供轻量 checkpoint 接力文件。

用户通常只需要记住 `fourli/checkpoint`，用于创建、查看或切换 checkpoint。已有 active checkpoint 的阶段边界更新由 `fourli/checkpoint-maintenance` 引导 agent 处理。

## 运行文件

```text
docs/checkpoints/
  .active_checkpoint
  <checkpoint-id>/
    checkpoint.md
```

## 边界

- checkpoint 不是需求设计。
- checkpoint 不是 implementation plan。
- checkpoint 不是执行日志。
- checkpoint 不是验证记录。
- 使用 superpowers 时，spec、writing-plans、execution、verification 仍由 superpowers 负责。

## Codex Hooks

插件提供 Codex hook 增强：

- `SessionStart`：注入 active checkpoint 的 delimited block。
- `PreCompact`：用 JSON `systemMessage` 做非阻断提醒。
- `Stop`：用 JSON `systemMessage` 做非阻断提醒。
```

- [ ] **Step 6: Remove old plugin directories**

Run:

```bash
git rm -r plugins/fourli-planning
rm -rf .codex-plugins/fourli-planning
```

Expected: no `fourli-planning` plugin directory remains.

- [ ] **Step 7: Verify metadata**

Run:

```bash
python3 -m json.tool marketplace.json >/dev/null
python3 -m json.tool .codex-plugins/fourli-checkpoint/.codex-plugin/plugin.json >/dev/null
test ! -e plugins/fourli-planning
test ! -e .codex-plugins/fourli-planning
```

Expected: all commands exit `0`.

- [ ] **Step 8: Commit**

```bash
git add marketplace.json README.md .codex-plugins/fourli-checkpoint/.codex-plugin/plugin.json .codex-plugins/fourli-checkpoint/README.md
git add -u plugins/fourli-planning
git commit -m "refactor(checkpoint): rename planning plugin"
```

### Task 2: Add User-Facing Checkpoint Skill And Scripts

**Files:**
- Create: `.codex-plugins/fourli-checkpoint/skills/fourli/checkpoint/SKILL.md`
- Create: `.codex-plugins/fourli-checkpoint/skills/fourli/checkpoint/agents/openai.yaml`
- Create: `.codex-plugins/fourli-checkpoint/skills/fourli/checkpoint/scripts/init-checkpoint.sh`
- Create: `.codex-plugins/fourli-checkpoint/skills/fourli/checkpoint/scripts/set-active-checkpoint.sh`

**Interfaces:**
- Produces: `fourli/checkpoint` skill
- Produces: `docs/checkpoints/<checkpoint-id>/checkpoint.md`
- Produces: `docs/checkpoints/.active_checkpoint`

- [ ] **Step 1: Create skill metadata**

Create `.codex-plugins/fourli-checkpoint/skills/fourli/checkpoint/SKILL.md`:

```markdown
---
name: fourli/checkpoint
description: Use when the user explicitly asks to create, inspect, or switch a lightweight checkpoint for a large task. A checkpoint records handoff state only; it must not replace the primary workflow for requirements design, implementation planning, execution, or verification.
---

# Fourli Checkpoint

用于给大任务创建一个轻量接力 checkpoint。用户通常只需要记住这个入口。

## Agent Rules

Always:
- Use this skill only when the user explicitly asks for a checkpoint, or asks to create, inspect, or switch one.
- Keep checkpoint content short and handoff-focused.
- Create a rough phase map only; it can be incomplete.
- Require only a final goal and at least one coarse phase that can start.

Never:
- Do not keep asking questions to fully refine the phase map.
- Do not start the primary workflow from this skill.
- Do not create implementation plans here.
- Do not track ordinary execution progress.
- Do not duplicate superpowers specs or plans.

## Runtime Files

```text
docs/checkpoints/
  .active_checkpoint
  <checkpoint-id>/
    checkpoint.md
```

## Scripts

Run from the project root:

```bash
sh <plugin-root>/skills/fourli/checkpoint/scripts/init-checkpoint.sh "Task Name"
sh <plugin-root>/skills/fourli/checkpoint/scripts/set-active-checkpoint.sh <checkpoint-id>
sh <plugin-root>/skills/fourli/checkpoint/scripts/set-active-checkpoint.sh
```
```

- [ ] **Step 2: Create OpenAI agent metadata**

Create `.codex-plugins/fourli-checkpoint/skills/fourli/checkpoint/agents/openai.yaml`:

```yaml
interface:
  display_name: "fourli/checkpoint"
  short_description: "Create, inspect, or switch a lightweight checkpoint"
  default_prompt: "Use $fourli/checkpoint to create, inspect, or switch a lightweight docs/checkpoints checkpoint for this large task without replacing the primary workflow."
```

- [ ] **Step 3: Create init script**

Create `.codex-plugins/fourli-checkpoint/skills/fourli/checkpoint/scripts/init-checkpoint.sh`:

```sh
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
```

- [ ] **Step 4: Create set-active script**

Create `.codex-plugins/fourli-checkpoint/skills/fourli/checkpoint/scripts/set-active-checkpoint.sh`:

```sh
#!/bin/sh
set -u

CHECKPOINT_ROOT="docs/checkpoints"
ACTIVE_FILE="${CHECKPOINT_ROOT}/.active_checkpoint"
CHECKPOINT_ID_VALUE="${1:-}"

if [ -z "$CHECKPOINT_ID_VALUE" ]; then
    if [ -f "$ACTIVE_FILE" ]; then
        current="$(cat "$ACTIVE_FILE" 2>/dev/null)"
        if [ -n "$current" ] && [ -f "${CHECKPOINT_ROOT}/${current}/checkpoint.md" ]; then
            echo "Active checkpoint: ${current}"
            echo "Path: ${CHECKPOINT_ROOT}/${current}/checkpoint.md"
        else
            echo "No valid active checkpoint."
        fi
    else
        echo "No active checkpoint."
    fi
    exit 0
fi

case "$CHECKPOINT_ID_VALUE" in
    */*|*..*)
        echo "[fourli-checkpoint] invalid checkpoint id" >&2
        exit 2
        ;;
esac

CHECKPOINT_FILE="${CHECKPOINT_ROOT}/${CHECKPOINT_ID_VALUE}/checkpoint.md"
[ -f "$CHECKPOINT_FILE" ] || {
    echo "[fourli-checkpoint] checkpoint not found: ${CHECKPOINT_FILE}" >&2
    exit 1
}

mkdir -p "$CHECKPOINT_ROOT"
printf "%s\n" "$CHECKPOINT_ID_VALUE" > "$ACTIVE_FILE"
echo "[fourli-checkpoint] active checkpoint: ${CHECKPOINT_ID_VALUE}"
```

- [ ] **Step 5: Verify user-facing scripts**

Run:

```bash
tmpdir="$(mktemp -d)"
plugin_root="$PWD/.codex-plugins/fourli-checkpoint"
cd "$tmpdir"
sh "$plugin_root/skills/fourli/checkpoint/scripts/init-checkpoint.sh" "i18n"
test -f docs/checkpoints/.active_checkpoint
id="$(cat docs/checkpoints/.active_checkpoint)"
test -f "docs/checkpoints/$id/checkpoint.md"
sh "$plugin_root/skills/fourli/checkpoint/scripts/set-active-checkpoint.sh"
cd -
rm -rf "$tmpdir"
```

Expected: command exits `0` and prints the active checkpoint path.

- [ ] **Step 6: Commit**

```bash
git add .codex-plugins/fourli-checkpoint/skills/fourli/checkpoint
git commit -m "feat(checkpoint): add user checkpoint skill"
```

### Task 3: Add Maintenance Skill And Runtime Scripts

**Files:**
- Create: `.codex-plugins/fourli-checkpoint/skills/fourli/checkpoint-maintenance/SKILL.md`
- Create: `.codex-plugins/fourli-checkpoint/skills/fourli/checkpoint-maintenance/agents/openai.yaml`
- Create: `.codex-plugins/fourli-checkpoint/skills/fourli/checkpoint-maintenance/scripts/resolve-checkpoint.sh`
- Create: `.codex-plugins/fourli-checkpoint/skills/fourli/checkpoint-maintenance/scripts/extract-inject-block.sh`
- Create: `.codex-plugins/fourli-checkpoint/skills/fourli/checkpoint-maintenance/scripts/validate-checkpoint.sh`
- Create: `.codex-plugins/fourli-checkpoint/skills/fourli/checkpoint-maintenance/scripts/finish-checkpoint.sh`

**Interfaces:**
- Consumes: `docs/checkpoints/.active_checkpoint`
- Consumes: `docs/checkpoints/<checkpoint-id>/checkpoint.md`
- Produces: active checkpoint path on stdout from `resolve-checkpoint.sh`
- Produces: inject block on stdout from `extract-inject-block.sh`

- [ ] **Step 1: Create maintenance skill**

Create `.codex-plugins/fourli-checkpoint/skills/fourli/checkpoint-maintenance/SKILL.md`:

```markdown
---
name: fourli/checkpoint-maintenance
description: Use only when an active checkpoint already exists and the task reaches a phase boundary, session start/resume, context handoff risk, direction change, compaction/stop moment, or overall completion. Do not use for ordinary execution progress.
---

# Fourli Checkpoint Maintenance

Agent-facing maintenance for an existing checkpoint.

## Trigger Only When

- A session starts or resumes and an active checkpoint exists.
- A phase boundary is reached.
- The next agent or window would lose important direction without an update.
- A direction change affects the phase map.
- A compact or stop handoff is happening.
- The overall task is complete and the active checkpoint should be closed.

## Read Rules

Start with the inject block:

```text
<!-- fourli-checkpoint:inject-start -->
...
<!-- fourli-checkpoint:inject-end -->
```

Use the inject block for:
- recovering current phase
- finding the next step
- locating must-read primary workflow docs
- deciding whether checkpoint maintenance is needed

Read the full checkpoint file only when:
- updating the phase map
- recording a direction change
- adding key evidence
- closing the checkpoint
- validating or repairing delimiters

## Never

- Do not update checkpoint after every small step.
- Do not create or revise the primary workflow's spec, implementation plan, execution checklist, or verification record.
- Do not duplicate superpowers documents.
- Do not write ordinary execution logs into checkpoint.

## Scripts

Run from the project root:

```bash
sh <plugin-root>/skills/fourli/checkpoint-maintenance/scripts/resolve-checkpoint.sh
sh <plugin-root>/skills/fourli/checkpoint-maintenance/scripts/extract-inject-block.sh docs/checkpoints/<id>/checkpoint.md
sh <plugin-root>/skills/fourli/checkpoint-maintenance/scripts/validate-checkpoint.sh docs/checkpoints/<id>/checkpoint.md
sh <plugin-root>/skills/fourli/checkpoint-maintenance/scripts/finish-checkpoint.sh
```
```

- [ ] **Step 2: Create maintenance OpenAI metadata**

Create `.codex-plugins/fourli-checkpoint/skills/fourli/checkpoint-maintenance/agents/openai.yaml`:

```yaml
interface:
  display_name: "fourli/checkpoint-maintenance"
  short_description: "Maintain an existing active checkpoint at handoff boundaries"
  default_prompt: "Use $fourli/checkpoint-maintenance only when an active checkpoint already exists and a phase boundary, handoff risk, direction change, compaction/stop moment, or closeout requires an update."
```

- [ ] **Step 3: Create resolve script**

Create `.codex-plugins/fourli-checkpoint/skills/fourli/checkpoint-maintenance/scripts/resolve-checkpoint.sh`:

```sh
#!/bin/sh
set -u

CHECKPOINT_ROOT="docs/checkpoints"
ACTIVE_FILE="${CHECKPOINT_ROOT}/.active_checkpoint"

clean_id() {
    printf "%s" "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

valid_id() {
    id="$1"
    [ -n "$id" ] || return 1
    case "$id" in
        */*|*..*) return 1 ;;
    esac
    return 0
}

canonicalize() {
    target="$1"
    if command -v realpath >/dev/null 2>&1; then
        realpath "$target" 2>/dev/null && return 0
    fi
    if command -v python3 >/dev/null 2>&1; then
        python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$target" 2>/dev/null && return 0
    fi
    return 1
}

within_checkpoint_root() {
    candidate="$1"
    root_real="$(canonicalize "$CHECKPOINT_ROOT")" || return 1
    cand_real="$(canonicalize "$candidate")" || return 1
    case "$cand_real" in
        "$root_real"/*) return 0 ;;
        *) return 1 ;;
    esac
}

resolve_id() {
    if [ -n "${CHECKPOINT_ID:-}" ]; then
        clean_id "$CHECKPOINT_ID"
        return 0
    fi
    [ -f "$ACTIVE_FILE" ] || return 1
    clean_id "$(cat "$ACTIVE_FILE" 2>/dev/null)"
}

[ -d "$CHECKPOINT_ROOT" ] || exit 0
CHECKPOINT_ID_VALUE="$(resolve_id)" || exit 0
valid_id "$CHECKPOINT_ID_VALUE" || exit 0

CHECKPOINT_FILE="${CHECKPOINT_ROOT}/${CHECKPOINT_ID_VALUE}/checkpoint.md"
[ -f "$CHECKPOINT_FILE" ] || exit 0
within_checkpoint_root "$CHECKPOINT_FILE" || exit 0

printf "%s\n" "$CHECKPOINT_FILE"
```

- [ ] **Step 4: Create extract script**

Create `.codex-plugins/fourli-checkpoint/skills/fourli/checkpoint-maintenance/scripts/extract-inject-block.sh`:

```sh
#!/bin/sh
set -u

CHECKPOINT_FILE="${1:-}"
[ -n "$CHECKPOINT_FILE" ] && [ -f "$CHECKPOINT_FILE" ] || exit 1

awk '
    /<!-- fourli-checkpoint:inject-start -->/ { in_block=1; seen_start=1; next }
    /<!-- fourli-checkpoint:inject-end -->/ { seen_end=1; exit }
    in_block {
        count++
        if (count <= 60) print
    }
    END {
        if (!seen_start || !seen_end) exit 2
        if (count > 60) exit 3
    }
' "$CHECKPOINT_FILE"
```

- [ ] **Step 5: Create validate script**

Create `.codex-plugins/fourli-checkpoint/skills/fourli/checkpoint-maintenance/scripts/validate-checkpoint.sh`:

```sh
#!/bin/sh
set -u

CHECKPOINT_FILE="${1:-}"
[ -n "$CHECKPOINT_FILE" ] && [ -f "$CHECKPOINT_FILE" ] || {
    echo "[fourli-checkpoint] checkpoint not found" >&2
    exit 1
}

START_COUNT=$(grep -c '<!-- fourli-checkpoint:inject-start -->' "$CHECKPOINT_FILE" || true)
END_COUNT=$(grep -c '<!-- fourli-checkpoint:inject-end -->' "$CHECKPOINT_FILE" || true)

[ "$START_COUNT" -eq 1 ] || {
    echo "[fourli-checkpoint] expected exactly one inject-start delimiter" >&2
    exit 2
}

[ "$END_COUNT" -eq 1 ] || {
    echo "[fourli-checkpoint] expected exactly one inject-end delimiter" >&2
    exit 3
}

LINES=$(sh "$(dirname "$0")/extract-inject-block.sh" "$CHECKPOINT_FILE" 2>/dev/null | wc -l | tr -d ' ')
[ "$LINES" -le 60 ] || {
    echo "[fourli-checkpoint] injection block exceeds 60 lines" >&2
    exit 4
}

echo "[fourli-checkpoint] checkpoint OK"
```

- [ ] **Step 6: Create finish script**

Create `.codex-plugins/fourli-checkpoint/skills/fourli/checkpoint-maintenance/scripts/finish-checkpoint.sh`:

```sh
#!/bin/sh
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHECKPOINT_ROOT="docs/checkpoints"
ACTIVE_FILE="${CHECKPOINT_ROOT}/.active_checkpoint"

CHECKPOINT_ID_VALUE="${1:-}"
if [ -z "$CHECKPOINT_ID_VALUE" ]; then
    [ -f "$ACTIVE_FILE" ] || {
        echo "[fourli-checkpoint] no active checkpoint"
        exit 0
    }
    CHECKPOINT_ID_VALUE="$(cat "$ACTIVE_FILE" 2>/dev/null)"
fi

case "$CHECKPOINT_ID_VALUE" in
    ""|*/*|*..*)
        echo "[fourli-checkpoint] invalid checkpoint id" >&2
        exit 2
        ;;
esac

CHECKPOINT_FILE="${CHECKPOINT_ROOT}/${CHECKPOINT_ID_VALUE}/checkpoint.md"
[ -f "$CHECKPOINT_FILE" ] || {
    echo "[fourli-checkpoint] checkpoint not found: ${CHECKPOINT_FILE}" >&2
    exit 1
}

sh "${SCRIPT_DIR}/validate-checkpoint.sh" "$CHECKPOINT_FILE" >/dev/null || {
    echo "[fourli-checkpoint] checkpoint template needs repair before finish: ${CHECKPOINT_FILE}" >&2
    exit 1
}

if [ -f "$ACTIVE_FILE" ] && [ "$(cat "$ACTIVE_FILE" 2>/dev/null)" = "$CHECKPOINT_ID_VALUE" ]; then
    rm -f "$ACTIVE_FILE"
    echo "[fourli-checkpoint] cleared active checkpoint: ${CHECKPOINT_ID_VALUE}"
else
    echo "[fourli-checkpoint] checkpoint is not current active checkpoint: ${CHECKPOINT_ID_VALUE}"
fi

echo "[fourli-checkpoint] historical checkpoint kept: ${CHECKPOINT_FILE}"
```

- [ ] **Step 7: Verify maintenance scripts**

Run:

```bash
tmpdir="$(mktemp -d)"
plugin_root="$PWD/.codex-plugins/fourli-checkpoint"
cd "$tmpdir"
sh "$plugin_root/skills/fourli/checkpoint/scripts/init-checkpoint.sh" "i18n"
checkpoint_file="$(sh "$plugin_root/skills/fourli/checkpoint-maintenance/scripts/resolve-checkpoint.sh")"
test -f "$checkpoint_file"
sh "$plugin_root/skills/fourli/checkpoint-maintenance/scripts/extract-inject-block.sh" "$checkpoint_file" | grep -q "## 阶段地图"
sh "$plugin_root/skills/fourli/checkpoint-maintenance/scripts/validate-checkpoint.sh" "$checkpoint_file"
sh "$plugin_root/skills/fourli/checkpoint-maintenance/scripts/finish-checkpoint.sh"
test ! -f docs/checkpoints/.active_checkpoint
test -f "$checkpoint_file"
cd -
rm -rf "$tmpdir"
```

Expected: all commands exit `0`; historical `checkpoint.md` remains after finish.

- [ ] **Step 8: Commit**

```bash
git add .codex-plugins/fourli-checkpoint/skills/fourli/checkpoint-maintenance
git commit -m "feat(checkpoint): add maintenance skill"
```

### Task 4: Add Codex Hook Wrappers With JSON Output

**Files:**
- Create: `.codex-plugins/fourli-checkpoint/hooks/hooks.json`
- Create: `.codex-plugins/fourli-checkpoint/hooks/emit-json.py`
- Create: `.codex-plugins/fourli-checkpoint/hooks/session-start.sh`
- Create: `.codex-plugins/fourli-checkpoint/hooks/pre-compact.sh`
- Create: `.codex-plugins/fourli-checkpoint/hooks/stop.sh`

**Interfaces:**
- Consumes: `PLUGIN_ROOT`
- Consumes: maintenance scripts from `skills/fourli/checkpoint-maintenance/scripts/`
- Produces: valid Codex hook JSON on stdout for all three hooks

- [ ] **Step 1: Create hook config**

Create `.codex-plugins/fourli-checkpoint/hooks/hooks.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "sh \"${PLUGIN_ROOT}/hooks/session-start.sh\"",
            "statusMessage": "Loading checkpoint"
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "sh \"${PLUGIN_ROOT}/hooks/pre-compact.sh\"",
            "statusMessage": "Checking checkpoint handoff"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "sh \"${PLUGIN_ROOT}/hooks/stop.sh\"",
            "timeout": 10,
            "statusMessage": "Checking checkpoint handoff"
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 2: Create JSON emitter**

Create `.codex-plugins/fourli-checkpoint/hooks/emit-json.py`:

```python
#!/usr/bin/env python3
import json
import sys

if len(sys.argv) != 3:
    print("usage: emit-json.py <event-name> <mode>", file=sys.stderr)
    sys.exit(2)

event_name = sys.argv[1]
mode = sys.argv[2]
message = sys.stdin.read()

payload = {"continue": True}

if mode == "additionalContext":
    payload["hookSpecificOutput"] = {
        "hookEventName": event_name,
        "additionalContext": message,
    }
elif mode == "systemMessage":
    payload["systemMessage"] = message
else:
    print("invalid mode: " + mode, file=sys.stderr)
    sys.exit(2)

print(json.dumps(payload, ensure_ascii=False))
```

- [ ] **Step 3: Create SessionStart wrapper**

Create `.codex-plugins/fourli-checkpoint/hooks/session-start.sh`:

```sh
#!/bin/sh
set -u

ROOT="${PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
SCRIPT_ROOT="${ROOT}/skills/fourli/checkpoint-maintenance/scripts"
RESOLVER="${SCRIPT_ROOT}/resolve-checkpoint.sh"
EXTRACTOR="${SCRIPT_ROOT}/extract-inject-block.sh"
EMITTER="${ROOT}/hooks/emit-json.py"

CHECKPOINT_FILE="$(sh "$RESOLVER" 2>/dev/null)" || exit 0
[ -n "$CHECKPOINT_FILE" ] || exit 0

CHECKPOINT_ID_VALUE="$(basename "$(dirname "$CHECKPOINT_FILE")")"
BLOCK="$(sh "$EXTRACTOR" "$CHECKPOINT_FILE" 2>/dev/null)"
STATUS=$?

if [ "$STATUS" -ne 0 ]; then
    printf "%s\n" "[fourli-checkpoint] active checkpoint exists but injection delimiters need repair: ${CHECKPOINT_FILE}" | python3 "$EMITTER" "SessionStart" "additionalContext"
    exit 0
fi

{
    echo "[fourli-checkpoint]"
    echo "role: checkpoint handoff only"
    echo "checkpoint: ${CHECKPOINT_ID_VALUE}"
    echo "rules:"
    echo "- checkpoint.md is a handoff index, not a requirements design, implementation plan, execution log, or verification record."
    echo "- Read the delimited block for orientation; read the full file only when maintenance is needed."
    echo "===BEGIN FOURLI CHECKPOINT==="
    printf "%s\n" "$BLOCK"
    echo "===END FOURLI CHECKPOINT==="
} | python3 "$EMITTER" "SessionStart" "additionalContext"
```

- [ ] **Step 4: Create PreCompact wrapper**

Create `.codex-plugins/fourli-checkpoint/hooks/pre-compact.sh`:

```sh
#!/bin/sh
set -u

ROOT="${PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
RESOLVER="${ROOT}/skills/fourli/checkpoint-maintenance/scripts/resolve-checkpoint.sh"
EMITTER="${ROOT}/hooks/emit-json.py"

CHECKPOINT_FILE="$(sh "$RESOLVER" 2>/dev/null)" || exit 0
[ -n "$CHECKPOINT_FILE" ] || exit 0

{
    echo "[fourli-checkpoint] Active checkpoint exists."
    echo "Before compaction, update it only if this turn reached a phase boundary, changed direction, created handoff risk, or completed the overall task."
    echo "Do not update checkpoint for ordinary execution progress."
} | python3 "$EMITTER" "PreCompact" "systemMessage"
```

- [ ] **Step 5: Create Stop wrapper**

Create `.codex-plugins/fourli-checkpoint/hooks/stop.sh`:

```sh
#!/bin/sh
set -u

ROOT="${PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
RESOLVER="${ROOT}/skills/fourli/checkpoint-maintenance/scripts/resolve-checkpoint.sh"
EMITTER="${ROOT}/hooks/emit-json.py"

CHECKPOINT_FILE="$(sh "$RESOLVER" 2>/dev/null)" || exit 0
[ -n "$CHECKPOINT_FILE" ] || exit 0

CHECKPOINT_ID_VALUE="$(basename "$(dirname "$CHECKPOINT_FILE")")"

{
    echo "[fourli-checkpoint] Active checkpoint: ${CHECKPOINT_ID_VALUE}"
    echo "Before stopping, update checkpoint only if this turn completed a phase, changed the phase map, created handoff risk, or completed the overall task."
    echo "If the overall task is complete, run finish-checkpoint.sh to clear the active checkpoint."
    echo "Do not update checkpoint for ordinary execution progress."
} | python3 "$EMITTER" "Stop" "systemMessage"
```

- [ ] **Step 6: Verify hook JSON with no active checkpoint**

Run from repository root:

```bash
PLUGIN_ROOT="$PWD/.codex-plugins/fourli-checkpoint" sh .codex-plugins/fourli-checkpoint/hooks/session-start.sh
PLUGIN_ROOT="$PWD/.codex-plugins/fourli-checkpoint" sh .codex-plugins/fourli-checkpoint/hooks/pre-compact.sh
PLUGIN_ROOT="$PWD/.codex-plugins/fourli-checkpoint" sh .codex-plugins/fourli-checkpoint/hooks/stop.sh
```

Expected: commands exit `0`; no output is acceptable because no active checkpoint exists.

- [ ] **Step 7: Verify hook JSON with active checkpoint**

Run:

```bash
tmpdir="$(mktemp -d)"
plugin_root="$PWD/.codex-plugins/fourli-checkpoint"
cd "$tmpdir"
sh "$plugin_root/skills/fourli/checkpoint/scripts/init-checkpoint.sh" "i18n"
PLUGIN_ROOT="$plugin_root" sh "$plugin_root/hooks/session-start.sh" | python3 -m json.tool >/dev/null
PLUGIN_ROOT="$plugin_root" sh "$plugin_root/hooks/pre-compact.sh" | python3 -m json.tool >/dev/null
PLUGIN_ROOT="$plugin_root" sh "$plugin_root/hooks/stop.sh" | python3 -m json.tool >/dev/null
PLUGIN_ROOT="$plugin_root" sh "$plugin_root/hooks/session-start.sh" | grep -q "hookSpecificOutput"
PLUGIN_ROOT="$plugin_root" sh "$plugin_root/hooks/pre-compact.sh" | grep -q "systemMessage"
PLUGIN_ROOT="$plugin_root" sh "$plugin_root/hooks/stop.sh" | grep -q "systemMessage"
cd -
rm -rf "$tmpdir"
```

Expected: all commands exit `0`.

- [ ] **Step 8: Commit**

```bash
git add .codex-plugins/fourli-checkpoint/hooks
git commit -m "feat(checkpoint): add codex hook wrappers"
```

### Task 5: Add AGENTS.md Guidance And Final Docs Pass

**Files:**
- Modify: `AGENTS.md`
- Modify: `.codex-plugins/fourli-checkpoint/README.md`
- Modify: `README.md`

**Interfaces:**
- Produces: durable guidance for non-hook agents
- Produces: user-facing docs that primarily mention `fourli/checkpoint`

- [ ] **Step 1: Add checkpoint guidance to AGENTS.md**

Append this section to `AGENTS.md`, preserving existing user instructions:

```markdown
## Fourli Checkpoint

If `docs/checkpoints/.active_checkpoint` exists, use `fourli/checkpoint-maintenance` only at session start/resume, phase boundaries, context handoff risk, direction changes, or task closeout.

For orientation, read only the delimited checkpoint inject block first. Read the full `checkpoint.md` only when updating direction changes, key evidence, closeout notes, closing the checkpoint, or repairing the checkpoint file.

Do not use checkpoint content as an implementation plan. The primary workflow owns requirements design, implementation planning, execution, and verification.
```

- [ ] **Step 2: Ensure README does not over-promote maintenance**

Verify `.codex-plugins/fourli-checkpoint/README.md` contains:

```markdown
用户通常只需要记住 `fourli/checkpoint`
```

Verify it does not tell users they must memorize `fourli/checkpoint-maintenance`.

- [ ] **Step 3: Scan old naming**

Run:

```bash
rg -n "fourli-planning|docs/planning|\\.active_plan|overview\\.md|planning-lite|active planning" README.md marketplace.json AGENTS.md .codex-plugins/fourli-checkpoint
```

Expected: no matches.

Run:

```bash
rg -n "planning" .codex-plugins/fourli-checkpoint README.md marketplace.json AGENTS.md
```

Expected: matches are allowed only for phrases like `implementation planning`.

- [ ] **Step 4: Commit**

```bash
git add AGENTS.md README.md .codex-plugins/fourli-checkpoint/README.md
git commit -m "docs(checkpoint): document agent handoff guidance"
```

### Task 6: End-To-End Verification

**Files:**
- No new files expected.
- Verify all files changed by Tasks 1-5.

**Interfaces:**
- Consumes: all scripts and metadata.
- Produces: verified implementation ready for review.

- [ ] **Step 1: Validate JSON metadata**

Run:

```bash
python3 -m json.tool marketplace.json >/dev/null
python3 -m json.tool .codex-plugins/fourli-checkpoint/.codex-plugin/plugin.json >/dev/null
python3 -m json.tool .codex-plugins/fourli-checkpoint/hooks/hooks.json >/dev/null
```

Expected: all commands exit `0`.

- [ ] **Step 2: Run full script lifecycle**

Run:

```bash
tmpdir="$(mktemp -d)"
plugin_root="$PWD/.codex-plugins/fourli-checkpoint"
cd "$tmpdir"
sh "$plugin_root/skills/fourli/checkpoint/scripts/init-checkpoint.sh" "i18n"
checkpoint_id="$(cat docs/checkpoints/.active_checkpoint)"
checkpoint_file="docs/checkpoints/$checkpoint_id/checkpoint.md"
test -f "$checkpoint_file"
sh "$plugin_root/skills/fourli/checkpoint/scripts/set-active-checkpoint.sh" "$checkpoint_id"
resolved="$(sh "$plugin_root/skills/fourli/checkpoint-maintenance/scripts/resolve-checkpoint.sh")"
test "$resolved" = "$checkpoint_file"
sh "$plugin_root/skills/fourli/checkpoint-maintenance/scripts/extract-inject-block.sh" "$checkpoint_file" | grep -q "## 当前接力"
sh "$plugin_root/skills/fourli/checkpoint-maintenance/scripts/validate-checkpoint.sh" "$checkpoint_file"
PLUGIN_ROOT="$plugin_root" sh "$plugin_root/hooks/session-start.sh" | python3 -m json.tool >/dev/null
PLUGIN_ROOT="$plugin_root" sh "$plugin_root/hooks/pre-compact.sh" | python3 -m json.tool >/dev/null
PLUGIN_ROOT="$plugin_root" sh "$plugin_root/hooks/stop.sh" | python3 -m json.tool >/dev/null
sh "$plugin_root/skills/fourli/checkpoint-maintenance/scripts/finish-checkpoint.sh"
test ! -f docs/checkpoints/.active_checkpoint
test -f "$checkpoint_file"
cd -
rm -rf "$tmpdir"
```

Expected: all commands exit `0`.

- [ ] **Step 3: Verify 60-line failure**

Run:

```bash
tmpdir="$(mktemp -d)"
plugin_root="$PWD/.codex-plugins/fourli-checkpoint"
cd "$tmpdir"
sh "$plugin_root/skills/fourli/checkpoint/scripts/init-checkpoint.sh" "too-long"
checkpoint_id="$(cat docs/checkpoints/.active_checkpoint)"
checkpoint_file="docs/checkpoints/$checkpoint_id/checkpoint.md"
awk '/<!-- fourli-checkpoint:inject-start -->/ { print; for (i=1; i<=61; i++) print "line " i; next } { print }' "$checkpoint_file" > checkpoint.tmp
mv checkpoint.tmp "$checkpoint_file"
if sh "$plugin_root/skills/fourli/checkpoint-maintenance/scripts/validate-checkpoint.sh" "$checkpoint_file"; then
    echo "expected validation failure" >&2
    exit 1
fi
cd -
rm -rf "$tmpdir"
```

Expected: command exits `0` because validation correctly fails inside the `if` block.

- [ ] **Step 4: Verify old directories are gone**

Run:

```bash
test ! -e plugins/fourli-planning
test ! -e .codex-plugins/fourli-planning
```

Expected: both tests exit `0`.

- [ ] **Step 5: Verify git state**

Run:

```bash
git status --short
```

Expected: only unrelated pre-existing user changes may remain. There should be no untracked old `fourli-planning` directory.

- [ ] **Step 6: Commit verification-only fixes if needed**

If verification in this task required fixes, commit those fixes:

```bash
git add .codex-plugins/fourli-checkpoint README.md marketplace.json AGENTS.md
git commit -m "fix(checkpoint): complete verification fixes"
```

If no fixes were needed, do not create an empty commit.
