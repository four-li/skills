---
name: think
description: Use when需求模糊、经常返工、用户要求先想清楚/问透，或已有 draft spec/design 需要被审问、补齐边界、失败路径和验收标准；不要用于已确认 plan 的机械执行。
---

# Fourli Think

把“需求审问”从“设计方案”里拆出来，减少做完才发现方向偏差。

这个 skill 不替代 `superpowers:brainstorming`。它只做两件事：

- **intent-intake**：初始需求太模糊时，做很短的意图澄清，让 brainstorming 有足够起点。
- **spec-grill**：已有 draft spec/design 后，审问这份草案，找出歧义、缺口、失败路径和不可验证的验收标准。

## 工作边界

- 不要写代码。
- 不要直接进入实现方案细节。
- 不要产出 implementation plan。
- 能从代码库、文档、现有约定确认的内容，先自己查，不要问用户。
- 始终一次只问一个问题。
- 不要把 `superpowers:brainstorming` 已经会问的问题完整重问一遍。

## 选择模式

先判断当前处在哪一阶段：

| 场景 | 使用模式 | 目标 |
| --- | --- | --- |
| 只有一句想法、目标/对象/成功标准不清楚 | `intent-intake` | 问到足够进入 brainstorming，不问到完整设计 |
| 已有 Superpowers design/spec、草案、方案摘要 | `spec-grill` | 审问草案，补齐边界和验收 |
| 用户说“先 think / grill / 问透 / 需求做透”但没有草案 | `intent-intake` | 先确认意图，再进入 brainstorming |
| 用户说“帮我审一下 spec / 这个方案有没有漏” | `spec-grill` | 对草案做需求审计 |
| 已经有明确 spec 和 plan，只是在执行 | 不使用 | 继续执行 plan |

## intent-intake

只解决“这件事到底要干什么”。不要试图替 brainstorming 完成全部设计。

### 结束条件

满足下面四项就停止追问：

- 目标清楚：这次要解决什么问题。
- 使用者/触发场景清楚：谁在什么情况下会用。
- 成功标准清楚：什么现象算完成。
- 关键非目标或硬约束清楚：这次明确不做什么，或不能破坏什么。

如果某个信息缺失但可以低风险假设，写成假设，不要继续盘问。

### 提问优先级

一次只问最会改变方向的问题：

1. 目标：这次到底要解决什么问题？
2. 成功标准：做到什么程度算完成？
3. 非目标：这次明确不做什么？
4. 约束：必须兼容什么、不能改什么？

不要在 intent-intake 阶段深挖架构、数据流、错误处理、测试细节；这些交给 `superpowers:brainstorming` 和后续 spec。

### 输出格式

结束时输出：

```md
## 意图澄清摘要

- 目标：
- 使用者/触发场景：
- 成功标准：
- 非目标：
- 硬约束：
- 当前假设：

## 下一步

- 如果用户确认，进入 `superpowers:brainstorming`，基于这个摘要产出 draft design/spec。
```

## spec-grill

用于已有 draft spec/design 之后。目标是审问“文档里的具体主张”，不是从零重新问需求。

### 先读草案

先阅读用户给出的草案、Superpowers design doc、issue、PRD 或方案摘要。没有草案时，不要假装在做 spec-grill，切回 `intent-intake`。

### 审问维度

按顺序检查：

1. **目标一致性**：spec 是否真的解决原始问题？
2. **范围和非目标**：哪些内容应该明确不做？
3. **Always / Ask first / Never**：
   - Always：实现时必须始终遵守什么？
   - Ask first：遇到什么情况必须先问用户？
   - Never：绝不能做什么？
4. **状态和分支**：不同输入、权限、状态、平台返回会走哪些路径？
5. **失败路径**：空数据、重复操作、权限不足、外部接口异常、超时、部分成功怎么办？
6. **验收标准**：每条需求能不能被命令、测试、截图、接口响应或人工检查验证？
7. **风险假设**：哪些地方是推断，不是用户明确确认？

### 提问规则

- 先列出最多 3 个最高风险缺口，再只问第一个问题。
- 问题必须绑定到草案里的具体缺口。
- 优先给选项，减少用户负担。
- 不要问草案已经明确回答的问题。
- 如果问题只影响实现细节，不影响需求边界或验收，记录为 plan 阶段处理，不在这里追问。

### 输出格式

每轮先给短审计，再问一个问题：

```md
## Spec 审问发现

- 高风险缺口：
- 中风险缺口：
- 可留到 plan 的细节：

## 当前最关键问题

[只问一个问题，最好给 2-3 个选项]
```

当高风险缺口消失后，输出：

```md
## Spec 补强摘要

- 需要写回 spec 的变更：
- Always：
- Ask first：
- Never：
- 验收标准：
- 仍保留的假设：

## 下一步

- 把以上内容写回 Superpowers design/spec，然后进入 `superpowers:writing-plans`。
```

## 与 Superpowers 的衔接

推荐顺序：

```text
intent-intake（只在初始需求很模糊时）
-> superpowers:brainstorming 产出 draft design/spec
-> spec-grill 审问草案
-> 写回 design/spec
-> superpowers:writing-plans
-> implementation
```

不要再固定执行：

```text
fourli-think 完整问透 -> superpowers:brainstorming 从头再问
```

这会造成重复盘问。`fourli-think` 只负责降低方向偏差；`superpowers:brainstorming` 负责把需求发展成设计；`spec-grill` 负责在 plan 前把设计审问到可验证。

## 禁止事项

- 不要把一串问题塞进同一条消息。
- 不要把“我理解的是不是这样”重复成无效寒暄。
- 不要太早给技术方案。
- 不要在没有草案时执行 spec-grill。
- 不要在 spec-grill 里重问草案已明确回答的问题。
- 不要把能从代码或文档确认的问题甩给用户。
