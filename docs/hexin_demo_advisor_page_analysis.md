# hexin_demo AdvisorPage 实现分析与调整方案

## 总结
`AdvisorPage` 当前采用“自定义后端 + 自定义工具调用解析”路径，核心可用，但在**安全性、组件命名一致性、工具编排完整性和多轮稳定性**上有明显改进空间。

## 当前实现链路
1. 页面初始化检测交易时段并创建会话（`A2uiMessageProcessor + StreamingGenUiConversation + CustomContentGenerator`）。
2. `CustomContentGenerator` 发送 OpenAI-compatible 请求，注册 `uiGenerationTool` 和少量数据工具。
3. 收到 `tool_calls` 后本地执行数据工具，必要时再发 follow-up 请求。
4. 对 `uiGenerationTool` 结果手动拼 `SurfaceUpdate + BeginRendering` 推送到 GenUI 渲染。

## 关键问题（按优先级）

### P0（必须先修）
- API Key 明文硬编码（且重复出现）
  - `examples/hexin_demo/lib/src/pages/advisor_page.dart:62`
  - `examples/hexin_demo/lib/src/config/secrets.dart:9`
- Prompt 组件名与 Catalog 不一致（`aiMessage` vs `ai_message`）
  - `examples/hexin_demo/lib/src/services/system_prompts.dart:78`
  - `packages/hexin_ai_ui/lib/src/components/ai_message.dart:51`
- 数据工具声明不完整，仅声明 `get_market_overview/get_realtime_quote`，但业务目标覆盖盘前/盘后更多能力
  - `examples/hexin_demo/lib/src/services/custom_content_generator.dart:122`
  - `examples/hexin_demo/lib/src/services/custom_content_generator.dart:131`
- `get_realtime_quote` 忽略入参，固定查询上证指数
  - `examples/hexin_demo/lib/src/services/custom_content_generator.dart:468`

### P1（稳定性与架构）
- DSL fallback 分支 `BeginRendering` 未带 `catalogId`，存在 catalog 解析风险
  - `examples/hexin_demo/lib/src/services/custom_content_generator.dart:619`
  - `examples/hexin_demo/lib/src/catalog/catalog.dart:15`
- follow-up 请求仅保留 `uiGenerationTool`，二轮数据编排能力下降
  - `examples/hexin_demo/lib/src/services/custom_content_generator.dart:536`
- 缺少超时、重试、最大 tool 轮次保护，弱网和异常响应下稳定性不足
  - `examples/hexin_demo/lib/src/services/custom_content_generator.dart:170`
  - `examples/hexin_demo/lib/src/services/custom_content_generator.dart:559`

### P2（体验与可维护）
- `buildIntradayPrompt(marketSummary: ...)` 已支持真实行情注入，但实际未接入调用路径
  - `examples/hexin_demo/lib/src/services/system_prompts.dart:91`
  - `examples/hexin_demo/lib/src/services/system_prompts.dart:139`
- 测试未覆盖 AdvisorPage 主链路（仅有 smoke 与解析类测试）
  - `examples/hexin_demo/test/widget_test.dart:14`

## 调整方案

### 阶段一：正确性与安全（P0）
1. 移除明文 API Key，统一改为 `--dart-define` 或设置页存储（可复用 `SettingsService` 模式）。
2. 修正 `SystemPrompts` 中组件名为 catalog 实际名称（例如 `ai_message`）。
3. 修复 `get_realtime_quote` 参数透传，使用传入 `stockCode` 查询。
4. 所有 `BeginRendering` 路径统一写入 `catalogId`（包括 DSL fallback 分支）。

### 阶段二：工具架构统一（P1）
1. 用现有 `examples/hexin_demo/lib/src/tools/*.dart` 构建 `AiTool` 注册表，替换手写 if/else 分发。
2. 首轮与 follow-up 使用同一套工具声明，避免二轮能力降级。
3. 增加请求 `timeout`、有限重试和最大 tool 轮次限制。

### 阶段三：体验与测试（P2）
1. 盘中会话初始化前先拉一次大盘概况，注入 `buildIntradayPrompt(marketSummary: ...)`。
2. 切换时段时支持按时段缓存会话，减少上下文丢失。
3. 补充测试：
   - Tool 分发与参数透传单测
   - UI 回流到 `onSubmit` 的 widget 测试
   - 假后端多轮 tool 调用集成测试

## 推荐落地顺序
1. 先做 P0（安全与准确性，改动小收益大）。
2. 再做 P1（工具注册表与稳定性）。
3. 最后做 P2（体验与测试完善）。
