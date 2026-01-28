# Hexin Demo Highlights 功能分析与 A2UI 改造方案

基于对 `hexin_demo` 中 `HighlightsPage` 的源码分析，以下是该功能当前的实现逻辑与 A2UI 协议的差异分析，以及迁移到 A2UI 所需的工作。

## 1. 现状分析 (`hexin_demo` 中的 Highlights)

### 核心实现逻辑
1.  **数据获取 (Pull Mode)**:
    *   页面通过 `HighlightsService` 向后端 REST API 发送 HTTP 请求。
    *   获取的数据是 **JSON 列表**，每个列表项包含一个 `markDown` 字段。
    *   这是一个典型的 **Client-Driven (客户端驱动)** 的拉取模式。

2.  **内容渲染 (DSL over Markdown)**:
    *   后端返回的数据中包含 Markdown 字符串。
    *   Markdown 字符串中嵌入了 ` ```dsl ... ``` ` 代码块。
    *   客户端使用 `DslMarkdownSection` 解析这些 Markdown，识别出 DSL 块，然后调用 `hexin_dsl` 库渲染成 Flutter 组件（如 `targetHeader`）。

3.  **状态管理**:
    *   所有的状态（列表数据 `_items`、加载状态 `_isLoading`）都维护在 Flutter 页面的 `State` (`_HighlightsPageState`) 中。

---

## 2. 与 A2UI 协议的差异

| 特性 | Hexin Highlights (现状) | A2UI (目标) | 差异点 |
| :--- | :--- | :--- | :--- |
| **交互模式** | **拉取 (Pull)**: 客户端主动调接口 | **推送 (Push)**: Server/Agent 主动发消息 | A2UI 需要长连接 (SSE/WebSocket) 或流式响应。 |
| **数据格式** | 专有 JSON + Markdown/DSL | **标准 A2UI Message** | A2UI 使用 `SurfaceUpdate` 等标准指令，不依赖 Markdown 包裹。 |
| **组件定义** | 嵌入在 Markdown 中的 DSL JSON | `components` 列表 (JSON) | 现有 DSL JSON 结构可能需要微调以适配 A2UI Schema。 |
| **渲染控制** | 客户端硬编码列表逻辑 (CustomScrollView) | 服务端定义布局 (Surface) | A2UI 中，列表本身也可以是一个组件 (`ListView`)，由服务端下发。 |
| **状态归属** | 客户端 (Flutter State) | 服务端 (DataModel) | A2UI 中，数据存储在 DataModel 中，客户端只负责绑定和显示。 |

---

## 3. 改造工作清单 (Migration Steps)

要将 `Highlights` 功能完全迁移到 A2UI 协议，需要进行以下改造：

### 第一步：服务端/Agent 改造 (最为关键)

现有的 REST API 只能返回静态数据，无法驱动 A2UI。你需要创建一个 **A2UI Adapter (适配层)** 或 **Mock Agent**：

1.  **建立连接**: 支持客户端接入（模拟或真实 SSE）。
2.  **构造 `SurfaceUpdate`**:
    *   不再返回 `NewsSummary` 列表。
    *   而是构建一个包含 `ListView` 或 `Column` 的组件树。
    *   将每个新闻项转换为一个 `NewsCard` 组件（基于现有的 `targetHeader` 修改）。
    *   **示例数据结构转换**:
        *   原: `{ "markDown": "```dsl {...}```" }`
        *   新: `{ "surfaceUpdate": { "components": [ { "id": "news_1", "component": { "NewsCard": { ...props... } } } ] } }`
3.  **构造 `DataModelUpdate`**:
    *   将具体的新闻标题、时间、内容放入 DataModel，让组件通过 `{ "path": "/news/1/title" }` 引用。

### 第二步：客户端改造 (`hexin_demo`)

1.  **废弃 `HighlightsService`**:
    *   移除直接的 HTTP 请求逻辑。

2.  **引入 `GenUiSurface`**:
    *   在 `HighlightsPage` 中，使用 `GenUiSurface(surfaceId: 'highlights_feed')` 替换原来的 `CustomScrollView`。
    *   这个 Surface 会自动监听 `A2uiMessageProcessor` 的更新。

3.  **接入 `ContentGenerator`**:
    *   在页面初始化时，调用 `contentGenerator.sendRequest` 发送一个指令（如 "进入看点页面"）。
    *   这将触发服务端推送 `highlights_feed` 的界面定义。

4.  **注册 Catalog**:
    *   确保 `HighlightsCatalog` 中的组件（如 `targetHeader`）已正确注册到全局 Catalog 中，以便 A2UI 引擎能识别并渲染它们。

### 第三步：交互保留 (如 Pull-to-Refresh)

A2UI 是服务端驱动的，但也支持客户端事件：

*   **下拉刷新**:
    *   客户端通过 `sendEvent` 发送 `{ "action": "refresh", "surfaceId": "highlights_feed" }`。
    *   服务端收到事件后，拉取最新新闻，并发送 `DataModelUpdate` 或 `SurfaceUpdate` 更新界面。

---

## 4. 总结

目前的 `Highlights` 实际上是一个 **"半动态"** 方案（框架硬编码 + 内容动态）。
迁移到 A2UI 将使其变为 **"全动态"** 方案。

**主要工作量在于：**
1.  **后端协议转换**：将现有的 API 数据包装成 A2UI 的 JSON 格式。
2.  **前端容器替换**：用 `GenUiSurface` 接管渲染权。
