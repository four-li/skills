---
name: code-audit
description: Use when the user explicitly invokes /code-audit or explicitly asks to audit changed code risk before release, merge, or after a bug fix.
---

# Code Audit

发布前的代码风险兜底。用于在需求开发、bug 修复或其他代码改动完成后，检查已改动代码是否存在真实风险。

## 使用边界

只在用户显式调用 `/code-audit`，或明确要求使用 code-audit 审核代码风险时使用。

默认审核当前 `git diff`。如果用户指定了文件、commit range、branch、PR 或代码片段，就审核用户指定范围。若 diff 为空，提示用户指定 staged diff、commit range 或代码片段。

## 只查这些风险

- 行为风险：逻辑错误、边界条件、异常处理、事务、并发、状态不一致、数据写入副作用。
- 业务语义风险：代码看起来能跑，但违反业务规则、状态流转、金额/库存/订单/会员等领域含义、权限归属、历史数据兼容或 bug 修复意图。
- 安全风险：鉴权/授权缺口、注入、路径/命令/文件操作风险、敏感信息泄漏、SSRF、反序列化、不可信输入。
- 发布兼容风险：数据库迁移、配置/env、依赖、API/DTO 兼容、队列、缓存、定时任务、回滚、幂等。

不要做代码优化、审美式命名建议、SOLID 讲解、架构重构、死代码清理或设计文档审查。没有明确生产风险的风格问题不要报。不要直接改代码。

## 审核流程

1. 先确认审核范围：看当前 diff 或用户指定范围；必要时查看 diff stat、相关调用方、迁移、配置、路由、权限和测试。
2. 再确认改动意图：如果不知道这次改动要实现或修复什么，先问用户一句。
3. 重点检查业务语义：不要因为代码干净、类型正确、测试能跑就默认业务正确。认真比对条件判断、状态流转、默认值、权限、金额、库存、时间、历史数据和副作用。
4. 只输出有风险链路的问题：说明为什么会出错、影响什么、最小修复方向是什么。
5. 证据不足时降低置信度或写“需要确认”，不要把猜测写成事实。

## 严重级别

- P0 Critical：高置信安全漏洞、数据丢失、资金/权限/核心流程错误，必须阻断。
- P1 High：明显逻辑错误、业务语义错误、兼容性破坏或高概率线上故障，合并前应修。
- P2 Medium：有实际风险但触发条件有限，建议本次修复或明确跟进。
- P3 Low：低影响风险、边界隐患或需要确认的残余风险，不阻断。

## 输出格式

```markdown
## Code Audit Findings

### P0 Critical
(none)

### P1 High
1. **[path/to/file.php:42] 标题**
   - 风险类型：行为 / 业务语义 / 安全 / 发布兼容
   - 问题：具体风险
   - 影响：可能后果
   - 最小修复建议：最小可行方向，不直接改代码
   - 置信度：高 / 中 / 低

### P2 Medium
(none)

### P3 Low
(none)

## Overall Assessment

- 结论：APPROVE / COMMENT / REQUEST_CHANGES
- 已检查：检查过的范围和关键上下文
- 未覆盖：没有验证的部分
- 残余风险：仍需人工确认或运行验证的点
```

如果未发现问题，明确写“未发现阻断风险”，并说明检查范围和残余风险。不要只写 LGTM。

## PHP 示例

```php
// 业务语义风险：0 元优惠券、免费订单或积分抵扣可能被误判为“没有金额”
if (!$discountAmount) {
    return false;
}
```

```php
// 状态流转风险：只检查订单归属，没有检查订单状态，可能允许已取消订单继续支付
if ($order->user_id !== $user->id) {
    throw new ForbiddenException();
}

$paymentService->pay($order);
```

```php
// 安全风险：用户输入直接拼接 SQL，存在注入风险
$sql = "SELECT * FROM users WHERE email = '" . $_GET['email'] . "'";
```

```php
// 发布兼容风险：新增配置没有默认值，旧环境未配置时可能传入 null
$timeout = config('payment.timeout');
$client->setTimeout($timeout);
```
