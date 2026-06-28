---
name: checkpoint-maintenance
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
sh <fourli-skills-root>/skills/checkpoint-maintenance/scripts/resolve-checkpoint.sh
sh <fourli-skills-root>/skills/checkpoint-maintenance/scripts/extract-inject-block.sh docs/checkpoints/<id>/checkpoint.md
sh <fourli-skills-root>/skills/checkpoint-maintenance/scripts/validate-checkpoint.sh docs/checkpoints/<id>/checkpoint.md
sh <fourli-skills-root>/skills/checkpoint-maintenance/scripts/finish-checkpoint.sh
```
