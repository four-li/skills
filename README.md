# Fourli Skills Plugins

Personal Codex plugins and skills by Fourli.

## Plugins

- `fourli-planning`: lightweight `docs/planning/overview.md` handoff planning for large tasks that use superpowers.

## Install In Codex

Add this repository as a Codex plugin marketplace, then install `fourli-planning`.

For local development:

```bash
codex plugin marketplace add /path/to/fourli-skills
```

For GitHub usage, add the cloned repository path as the marketplace root.

## fourli-planning

`fourli-planning` keeps one project-local overview file:

```text
docs/planning/
  .active_plan
  <task-id>/
    overview.md
```

It is intentionally lightweight:

- no `.planning/`
- no `task_plan.md`, `findings.md`, or `progress.md`
- no PreToolUse hook
- no blocking Stop gate
- no automatic completion judgment

Superpowers still owns spec, implementation plan, execution, and verification.
