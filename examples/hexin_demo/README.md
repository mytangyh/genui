# Hexin Demo - 智能投资顾问

一个基于 GenUI 框架的证券交易应用技术验证 Demo，展示 AI 驱动的智能投资顾问功能。

## 功能特性

本 Demo 展示了如何使用 GenUI 框架构建动态、交互式的金融应用界面：

- **智能投资顾问**: AI 驱动的投资建议系统
- **投资组合管理**: 实时展示持仓、收益、风险等信息
- **风险评估**: 自动分析投资组合风险并提供优化建议
- **交易推荐**: 基于用户风险偏好生成个性化交易建议
- **可视化图表**: 股票走势图、资产配置饼图等
- **自定义组件目录**: 6 个金融领域专用 UI 组件

## 自定义组件

Demo 实现了以下金融领域专用组件：

1. **StockChart** - 股票走势图（支持分时图和K线图）
2. **PortfolioSummary** - 投资组合摘要
3. **RiskAssessmentCard** - 风险评估卡片
4. **TradeRecommendation** - 交易推荐
5. **AssetAllocationPie** - 资产配置饼图
6. **MarketNewsCard** - 市场新闻卡片

## 快速开始

### 前置要求

- Flutter >= 3.35.7
- Dart >= 3.9.2

### 选项 1: 使用 Google Generative AI（默认）

> ⚠️ **警告**: 此选项仅用于演示。生产环境请使用 Firebase AI。

1. 获取 API Key：从 [Google AI Studio](https://aistudio.google.com/app/apikey) 获取 Gemini API 密钥

2. 运行应用：
   ```bash
   flutter run -d <device> --dart-define=GEMINI_API_KEY=your_api_key
   ```

   或设置环境变量：
   ```bash
   export GEMINI_API_KEY=your_api_key_here
   flutter run -d <device> --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY
   ```

### 选项 2: 使用 Firebase AI

1. **配置 Firebase**: 参考主 genui 包的 [README.md](../../packages/genui/README.md#configure-firebase-ai-logic) 配置 Firebase：
   - 创建 Firebase 项目
   - 使用 FlutterFire CLI 生成 `firebase_options.dart`

2. **切换后端**: 在 `lib/src/config/configuration.dart` 中修改：
   ```dart
   const AiBackend aiBackend = AiBackend.firebase;
   ```

3. **运行应用**:
   ```bash
   flutter run -d <device>
   ```

## 使用场景示例

### 1. 查看投资组合
用户: "我的投资组合情况如何？"
AI: 展示 PortfolioSummary 组件，显示总资产、盈亏、持仓明细

### 2. 风险评估
用户: "帮我评估一下当前的风险"
AI: 展示 RiskAssessmentCard，分析波动率、分散度，并提供优化建议

### 3. 获取投资建议
用户: "我想调整投资组合，降低风险"
AI: 根据风险偏好，使用 TradeRecommendation 展示具体的买卖建议

### 4. 查看股票
用户: "帮我看看贵州茅台的走势"
AI: 使用 StockChart 展示股票走势图，提供技术分析

## 技术架构

```
hexin_demo/
├── lib/
│   ├── main.dart                 # 应用入口
│   └── src/
│       ├── config/
│       │   └── configuration.dart    # AI 后端配置
│       ├── catalog/              # 自定义金融组件
│       ├── tools/                # 业务工具（工具调用）
│       ├── models/               # 数据模型
│       ├── services/             # 模拟数据服务
│       └── pages/
│           └── advisor_page.dart # 主页面
└── pubspec.yaml
```

## 数据说明

**本 Demo 使用模拟数据进行演示**，不涉及真实交易。模拟数据包括：

- 投资组合数据（持仓、成本、收益等）
- 股票行情数据（价格、走势、成交量等）
- 风险评估数据（波动率、分散度等）
- 推荐数据（买卖建议、目标价等）

如需接入真实股票数据 API，可以扩展 `MockDataService` 并集成第三方数据源。

## 开发指南

### 添加新组件

1. 在 `lib/src/catalog/` 创建新组件文件
2. 定义 JSON Schema
3. 实现 `CatalogItem` 和 Widget Builder
4. 在 `catalog.dart` 中注册组件
5. 在系统提示中说明组件用途

### 添加新工具

1. 在 `lib/src/tools/` 创建工具文件
2. 继承 `DynamicAiTool`
3. 定义参数 Schema
4. 实现 `invoke` 方法
5. 在主页面注册工具

## 注意事项

- 本应用仅用于技术验证和学习目的
- 不提供真实的投资建议
- 不涉及真实交易操作
- AI 生成的内容仅供参考

## 许可证

BSD-3-Clause

## 反馈与贡献

欢迎提交 Issue 或 Pull Request 到 [flutter/genui](https://github.com/flutter/genui) 仓库。
