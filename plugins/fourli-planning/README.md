# fourli-planning

Lightweight overview planning for large tasks.

Use it when a task is large enough to need a durable handoff index, but the real design and execution flow still belongs to superpowers.

## Runtime Files

Inside each project:

```text
docs/planning/
  .active_plan
  <task-id>/
    overview.md
```

## Scripts

Run from a project root:

```bash
sh <plugin-root>/scripts/init-overview.sh "Task Name"
sh <plugin-root>/scripts/set-active-overview.sh <task-id>
sh <plugin-root>/scripts/finish-overview.sh
```

## Hooks

The plugin ships lightweight Codex hook scripts:

- `SessionStart`: injects only the delimited overview handoff block.
- `PreCompact`: reminds the agent to keep handoff state current.
- `Stop`: non-blocking reminder to update or finish the active overview.
