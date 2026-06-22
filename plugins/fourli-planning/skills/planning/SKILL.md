---
name: fourli-planning
description: Use when maintaining lightweight docs/planning overview files for large tasks, creating or switching active planning, recovering task direction after context loss, or updating the handoff index that supports superpowers without replacing its spec/plan/execute/verification flow.
---

# Fourli Planning

Lightweight overview planning for large tasks. It keeps one project-local `docs/planning/<task-id>/overview.md` file so a new agent window can recover direction without replacing superpowers.

## Boundary

- `overview.md` is a handoff index, not an implementation plan.
- Superpowers still owns spec, implementation plan, execution, and verification.
- Do not maintain `task_plan.md`, `findings.md`, or `progress.md`.
- Do not read or create `.planning/`.
- Do not require every superpowers subtask to be checked off.
- Update overview only when the phase boundary, handoff, direction, key risk, or acceptance meaning changes.

## Runtime Files

Projects use:

```text
docs/planning/
  .active_plan
  2026-06-22-i18n/
    overview.md
```

Active resolution order:

1. `$PLAN_ID`
2. `docs/planning/.active_plan`
3. no active overview

Never fall back to the newest directory.

## Script Location

When this skill is installed from the plugin, scripts live under the same plugin:

```text
plugins/fourli-planning/scripts/
```

If a script path is needed, locate it relative to the installed plugin root. Do not hard-code a user home path.

## Creating An Overview

Run the plugin script from a project root:

```bash
sh <plugin-root>/scripts/init-overview.sh "Task Name"
```

Task IDs default to `YYYY-MM-DD-Task Name` and may contain non-English text. Reject empty names, `/`, and `..`.

## Overview Template Contract

The injected handoff area must be wrapped by delimiters:

```markdown
<!-- planning-lite:inject-start -->

# 2026-06-22-i18n

## Goal

One sentence describing the final state.

## Boundary

- Do:
- Do not:

## Phase Overview

| Phase | Status | Depends on | Superpowers entry | Acceptance |
|------|------|------|------------------|------|
| 1. Confirm scope | in_progress | none | docs/superpowers/specs/... | phase-level signal |

## Current Handoff

- Current goal:
- Current phase:
- Next step:
- Recently completed:
- Do not do:
- Must-read superpowers docs:

<!-- planning-lite:inject-end -->

## Direction Changes

- 2026-06-22: Because X, changed Y to Z. Impact: ...

## Key Evidence

- Short facts that affect later decisions only.

## Closeout Notes

- One sentence per completed phase.
```

Status values are `pending`, `in_progress`, and `complete`.

`Acceptance` only records a phase-level completion signal or link. Do not put execution steps, test matrices, or task breakdowns there.

## Update Rules

Update `overview.md` only when:

- Phase status changes.
- Current handoff changes.
- Next step changes.
- Direction changes.
- Key risk or acceptance meaning changes.
- Evidence affects later decisions.

Do not write ordinary execution logs into overview.

## Finish

When the overall task is complete, run from the project root:

```bash
sh <plugin-root>/scripts/finish-overview.sh
```

This clears `docs/planning/.active_plan` and keeps historical overview files.
