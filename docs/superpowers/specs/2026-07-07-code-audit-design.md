# /code-audit Skill Design

## 目标

新增 `/code-audit` skill，用于在需求开发、bug 修复或其他代码改动完成后，审核已改动代码是否存在会影响生产行为、安全或发布兼容性的风险。

这个 skill 的核心价值是“风险审核”，不是代码优化、架构重构或设计文档审查。它应该像一个冷静的代码审查者：先确认审核范围和改动意图，再基于 diff、上下文和业务语义寻找真实风险，只报告问题和最小修复建议，不直接修改代码。

## 使用方式

`/code-audit` 仅显式触发。用户输入 `/code-audit`、明确要求使用 code-audit 审核代码，或要求审核当前改动风险时才使用。

默认审核当前工作区的 `git diff`。同时支持用户指定范围：文件、commit range、branch、PR 或粘贴的代码片段。若当前 diff 为空，skill 应提示用户指定 staged diff、commit range 或代码片段。

## 内容语言

`SKILL.md` 正文使用中文，包含流程、边界、输出模板和示例。PHP 是示例优先语言，但规则不限制语言。YAML frontmatter 的 `description` 保持英文，只写触发条件，不写流程或功能摘要。`agents/openai.yaml` 的 `short_description` 使用中文。

## 审核边界

### 核心范围

- 行为风险：逻辑错误、边界条件、异常处理、状态一致性、事务、并发、数据写入副作用。
- 业务语义风险：代码看起来正确，但违反业务规则、状态流转、金额/库存/会员/订单等领域语义、权限归属、历史数据兼容或 bug 修复意图。
- 安全风险：鉴权、授权、注入、路径/命令/文件操作、敏感信息泄漏、SSRF、反序列化、不可信输入。
- 发布兼容风险：数据库迁移、配置/env、依赖、API/DTO 兼容、队列、缓存、定时任务、回滚、幂等。

### 非目标

- 不做代码优化。
- 不做审美式命名建议。
- 不把 SOLID、架构重构、删除死代码作为主线。
- 不审查完整设计文档。
- 不直接修改代码。
- 没有明确生产风险的风格问题不作为 finding 输出。

测试缺口不作为独立核心维度。但当缺少验证会放大某个真实风险时，可以在对应风险项里说明。

## 审核流程

1. 确认范围：读取当前 diff 或用户指定范围，必要时用 `git status -sb`、`git diff --stat`、`git diff`、`git diff --staged`、`git log` 辅助判断。
2. 确认意图：如果从上下文看不出这次改动要实现或修复什么，先问用户一句，避免只按实现猜需求。
3. 阅读上下文：查看相邻代码、调用方、被调用方、已有测试、迁移、配置、路由、权限和领域模型，理解改动所在业务边界。
4. 风险扫描：优先查行为风险和业务语义风险，再查安全风险和发布兼容风险。
5. 形成 findings：只输出有明确风险链路的问题。不要把偏好、风格、抽象建议包装成风险。
6. 给出结论：按最严重问题判断是否阻断，并说明审核过什么、没覆盖什么、残余风险是什么。

大 diff 时先按文件和模块分组，再分批审核。混合关注点时按功能或业务域组织 findings，而不是按文件顺序机械输出。

## 严重级别

- P0 Critical：高置信的安全漏洞、数据丢失、资金/权限/核心流程错误，必须阻断。
- P1 High：明显逻辑错误、业务语义错误、兼容性破坏或高概率线上故障，合并前应修复。
- P2 Medium：有实际风险但触发条件有限，建议本次修复或明确跟进。
- P3 Low：低影响风险、边界隐患或需要确认的残余风险，不阻断。

若证据不足，应降低置信度或写入“需要确认”，不要把猜测写成事实。

## 输出格式

审核结果使用风险优先格式，findings 放在最前面：

```markdown
## Code Audit Findings

### P0 Critical

(none)

### P1 High

1. **[path/to/file.php:42] 标题**
   - 风险类型：行为 / 业务语义 / 安全 / 发布兼容
   - 问题：具体说明代码哪里可能出错
   - 影响：说明可能造成的生产后果
   - 最小修复建议：给出最小可行修复方向，不直接改代码
   - 置信度：高 / 中 / 低

### P2 Medium

(none)

### P3 Low

(none)

## Overall Assessment

- 结论：APPROVE / COMMENT / REQUEST_CHANGES
- 已检查：列出检查过的范围和关键上下文
- 未覆盖：列出没有验证的部分
- 残余风险：说明仍需人工确认或运行验证的点
```

如果未发现风险，应明确写“未发现阻断风险”，并说明检查范围和残余风险，不输出空泛的 LGTM。

## PHP 示例

### 业务语义风险

```php
// 风险：0 元优惠券、免费订单或积分抵扣场景可能被误判为“没有金额”
if (!$discountAmount) {
    return false;
}
```

### 状态流转风险

```php
// 风险：只检查订单归属，没有检查订单状态，可能允许已取消订单继续支付
if ($order->user_id !== $user->id) {
    throw new ForbiddenException();
}

$paymentService->pay($order);
```

### 安全风险

```php
// 风险：用户输入直接拼接 SQL，存在注入风险
$sql = "SELECT * FROM users WHERE email = '" . $_GET['email'] . "'";
```

### 发布兼容风险

```php
// 风险：新增配置没有默认值，旧环境未配置时可能传入 null 导致请求异常
$timeout = config('payment.timeout');
$client->setTimeout($timeout);
```

## 仓库影响范围

实现时新增：

- `skills/code-audit/SKILL.md`
- `skills/code-audit/agents/openai.yaml`

同时更新：

- `README.md` skills 表格和更新命令中的 skill 列表

不需要新增 hook，不需要新增脚本，不需要修改 checkpoint 逻辑。

## 参考来源取舍

- 借鉴 mattpocock/skills：固定 diff 基线、先确认比较范围、不要在未明确范围时审核。
- 借鉴 addyosmani/agent-skills：风险优先、严重级别、说明验证范围和残余风险。
- 借鉴 obra/superpowers：独立 reviewer 心智，只围绕目标和 diff 审查，不被实现者叙述带偏。
- 借鉴本地 `code-review-expert`：保留 P0-P3、preflight、security/reliability checklist；移除 SOLID、removal plan 和自动修复导向，避免与 `code-opt` 重叠。
