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
