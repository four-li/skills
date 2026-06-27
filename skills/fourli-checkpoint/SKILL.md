---
name: fourli-checkpoint
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
sh <fourli-skills-root>/skills/fourli-checkpoint/scripts/init-checkpoint.sh "Task Name"
sh <fourli-skills-root>/skills/fourli-checkpoint/scripts/set-active-checkpoint.sh <checkpoint-id>
sh <fourli-skills-root>/skills/fourli-checkpoint/scripts/set-active-checkpoint.sh
```
