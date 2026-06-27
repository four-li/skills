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
