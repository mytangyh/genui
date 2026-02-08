# genui 与 travel_app 详解

## 总体结论
`travel_app` 的核心是一个“LLM 工具调用驱动的 UI 状态机”：
- `Prompt + Catalog + Tools` 决定 AI 能生成什么。
- `GenUiConversation + A2uiMessageProcessor + GenUiSurface` 负责把 AI 指令变成可交互 Flutter UI。
- 用户交互事件再回流给 AI，形成持续迭代的闭环。

## 1. genui 核心机制

### 1.1 组件词表（Catalog）
- `Catalog/CatalogItem` 定义 AI 可用组件、参数 Schema、以及 Flutter 构建函数。
- AI 只能在该词表内组合 UI。
- 关键位置：`packages/genui/lib/src/model/catalog.dart:21`、`packages/genui/lib/src/model/catalog_item.dart:44`

### 1.2 会话编排（GenUiConversation）
- 监听 AI 流：`contentGenerator.a2uiMessageStream`。
- 监听 UI 交互流：`a2uiMessageProcessor.onSubmit`，并自动 `sendRequest` 下一轮。
- 维护对话历史 `ValueNotifier<List<ChatMessage>>`。
- 关键位置：`packages/genui/lib/src/facade/gen_ui_conversation.dart:25`、`packages/genui/lib/src/facade/gen_ui_conversation.dart:42`、`packages/genui/lib/src/facade/gen_ui_conversation.dart:148`

### 1.3 Surface 状态机（A2uiMessageProcessor）
- 处理四类消息：`SurfaceUpdate`、`BeginRendering`、`DataModelUpdate`、`SurfaceDeletion`。
- 维护 surface 定义、DataModel，并广播 `SurfaceAdded/Updated/Removed`。
- 将用户点击动作封装为 `UserUiInteractionMessage`。
- 关键位置：`packages/genui/lib/src/core/a2ui_message_processor.dart:87`、`packages/genui/lib/src/core/a2ui_message_processor.dart:152`

### 1.4 动态渲染执行（GenUiSurface）
- 根据 `UiDefinition` + `Catalog` 递归构建 Flutter Widget。
- 捕获 UI 事件并注入 `surfaceId` 回传 host。
- 关键位置：`packages/genui/lib/src/core/genui_surface.dart:24`、`packages/genui/lib/src/core/genui_surface.dart:84`

### 1.5 数据绑定与响应式更新
- `DataModel` 提供路径化状态存储。
- `DataContext` 处理相对/绝对路径。
- 控件通过 `subscribeToString/subscribeToObjectArray` 订阅，输入变更直接 `update(path)`。
- 关键位置：`packages/genui/lib/src/model/data_model.dart:117`、`packages/genui/lib/src/core/widget_utilities.dart:67`

### 1.6 AI 工具循环
- 内置工具：`surfaceUpdate`、`beginRendering`、`deleteSurface`。
- 生成器还注入伪工具 `provideFinalOutput`，强制一次回合收束。
- 关键位置：`packages/genui/lib/src/core/ui_tools.dart:18`、`packages/genui_google_generative_ai/lib/src/google_generative_ai_content_generator.dart:344`、`packages/genui_firebase_ai/lib/src/firebase_ai_content_generator.dart:343`

## 2. travel_app 核心实现

### 2.1 启动与配置
- `main()` 中按后端决定是否初始化 Firebase。
- 预加载图片索引 JSON，并开启 GenUI 日志。
- 默认后端是 `googleGenerativeAi`。
- 关键位置：`examples/travel_app/lib/main.dart:30`、`examples/travel_app/lib/main.dart:34`、`examples/travel_app/lib/main.dart:46`、`examples/travel_app/lib/src/config/configuration.dart:16`

### 2.2 页面核心装配
- `TravelPlannerPage` 在 `initState` 完成三件事：
1. 创建 `A2uiMessageProcessor(catalogs: [travelAppCatalog])`
2. 创建 `ContentGenerator`（Google/Firebase 二选一）
3. 创建 `GenUiConversation`
- 关键位置：`examples/travel_app/lib/src/travel_planner_page.dart:66`、`examples/travel_app/lib/src/travel_planner_page.dart:76`、`examples/travel_app/lib/src/travel_planner_page.dart:98`

### 2.3 业务组件词表
- `travelAppCatalog` 注册旅行域组件：
`TravelCarousel`、`InputGroup`、`Itinerary`、`ListingsBooker`、`Trailhead` 等。
- 关键位置：`examples/travel_app/lib/src/catalog.dart:27`

### 2.4 UI 显示层
- `Conversation` 按消息类型渲染：用户消息、AI 文本、`GenUiSurface`。
- 关键位置：`examples/travel_app/lib/src/widgets/conversation.dart:15`、`examples/travel_app/lib/src/widgets/conversation.dart:46`、`examples/travel_app/lib/src/widgets/conversation.dart:71`

### 2.5 输入与事件回流
- 输入类组件（`TextInputChip`、`DateInputChip`、`OptionsFilterChipInput`、`CheckboxFilterChipsInput`）都写回 DataModel 路径。
- 行为类组件（`TravelCarousel`、`Trailhead`、`InputGroup`、`Itinerary`）触发 `UserActionEvent`，携带上下文。
- 关键位置：
  - `examples/travel_app/lib/src/catalog/text_input_chip.dart:93`
  - `examples/travel_app/lib/src/catalog/date_input_chip.dart:145`
  - `examples/travel_app/lib/src/catalog/options_filter_chip_input.dart:126`
  - `examples/travel_app/lib/src/catalog/checkbox_filter_chips_input.dart:142`
  - `examples/travel_app/lib/src/catalog/travel_carousel.dart:250`
  - `examples/travel_app/lib/src/catalog/input_group.dart:158`
  - `examples/travel_app/lib/src/catalog/trailhead.dart:132`
  - `examples/travel_app/lib/src/catalog/itinerary.dart:561`

### 2.6 业务工具：酒店搜索与预订
- `ListHotelsTool` 暴露 `listHotels` 给模型。
- `BookingService` 提供 mock 酒店与预订流程。
- `ListingsBooker` 根据 `listingSelectionIds` 汇总账单并完成下单动作。
- 关键位置：`examples/travel_app/lib/src/tools/booking/list_hotels_tool.dart:11`、`examples/travel_app/lib/src/tools/booking/booking_service.dart:10`、`examples/travel_app/lib/src/catalog/listings_booker.dart:52`

### 2.7 Prompt 驱动流程控制
- `prompt` 明确要求 AI 在旅行规划中按阶段推进：灵感 -> 目的地 -> 行程 -> 预订。
- 约束必须使用 `surfaceUpdate`/`beginRendering`，并要求输入控件绑定 DataModel path。
- 关键位置：`examples/travel_app/lib/src/travel_planner_page.dart:247`

## 3. travel_app 的核心执行链路

```text
初始化：
  processor = A2uiMessageProcessor(catalogs=[travelAppCatalog])
  generator = Google/FirebaseContentGenerator(systemInstruction=prompt, additionalTools=[ListHotelsTool])
  conversation = GenUiConversation(processor, generator)

用户输入：
  _sendPrompt(text)
  -> conversation.sendRequest(UserMessage.text(text))

模型推理回合（工具调用循环）：
  模型调用 surfaceUpdate / beginRendering / dataModelUpdate / deleteSurface / listHotels
  -> A2uiMessageProcessor.handleMessage(...)
  -> surfaceUpdates 广播
  -> 对话中新增或更新 AiUiMessage
  -> Conversation 渲染 GenUiSurface
  -> GenUiSurface 根据 catalog 递归构建 Flutter 组件

用户交互回流：
  输入组件更新 DataModel(path)
  行为组件 dispatch UserActionEvent(context)
  -> A2uiMessageProcessor.handleUiEvent(...)
  -> onSubmit 产生 UserUiInteractionMessage(JSON)
  -> GenUiConversation 自动 sendRequest(下一轮)

业务闭环：
  listHotels 返回 listings + listingSelectionId
  -> TravelCarousel 展示候选
  -> 用户选择后进入 Itinerary/ListingsBooker
  -> 继续事件回流，模型持续优化 UI 与行程
```

## 4. 一句话总结
`travel_app` 把“页面编排权”交给 AI，但把“组件边界、数据结构、工具能力、渲染执行与状态同步”牢牢留在 Flutter 客户端，这就是它可控且可迭代的核心实现逻辑。
