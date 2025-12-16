// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
//UNCOMMENT_FOR_FIREBASE
// import 'package:genui_firebase_ai/genui_firebase_ai.dart';

import 'package:genui_google_generative_ai/genui_google_generative_ai.dart';

import '../catalog/catalog.dart';
import '../config/configuration.dart';
import '../services/mock_data_service.dart';
import '../tools/analyze_risk_tool.dart';
import '../tools/get_portfolio_tool.dart';
import '../tools/get_recommendations_tool.dart';
import '../tools/get_stock_data_tool.dart';

/// Main advisor page for hexin_demo.
class AdvisorPage extends StatefulWidget {
  const AdvisorPage({super.key});

  @override
  State<AdvisorPage> createState() => _AdvisorPageState();
}

class _AdvisorPageState extends State<AdvisorPage> {
  late final A2uiMessageProcessor _a2uiMessageProcessor;
  late final GenUiConversation _genUiConversation;
  late final MockDataService _dataService;

  final _textController = TextEditingController();
  final _surfaceIds = <String>[];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeConversation();
  }

  void _initializeConversation() {
    // Initialize data service
    _dataService = MockDataService();

    // Create catalog combining core and financial components
    final catalog = Catalog([
      ...CoreCatalogItems.asCatalog().items,
      ...FinancialCatalog.getCatalog().items,
    ]);

    // Create A2uiMessageProcessor
    _a2uiMessageProcessor = A2uiMessageProcessor(catalogs: [catalog]);

    // Create ContentGenerator based on configuration
    final ContentGenerator contentGenerator;

    switch (aiBackend) {
      case AiBackend.firebase:
        //UNCOMMENT_FOR_FIREBASE
        // contentGenerator = FirebaseAiContentGenerator(
        //   catalog: catalog,
        //   systemInstruction: _getSystemPrompt(),
        //   tools: tools,
        // );
        throw UnimplementedError(
          'Firebase AI backend is not configured. '
          'Please uncomment the Firebase code in advisor_page.dart '
          'and ensure Firebase is properly set up.',
        );

      case AiBackend.googleGenerativeAi:
        const apiKey = String.fromEnvironment('GEMINI_API_KEY');
        if (apiKey.isEmpty) {
          throw Exception(
            'GEMINI_API_KEY not found. '
            'Please run with: flutter run --dart-define=GEMINI_API_KEY=your_key',
          );
        }

        contentGenerator = GoogleGenerativeAiContentGenerator(
          catalog: catalog,
          apiKey: apiKey,
          systemInstruction: _getSystemPrompt(),
          additionalTools: [
            GetPortfolioTool(_dataService),
            GetStockDataTool(_dataService),
            AnalyzeRiskTool(_dataService),
            GetRecommendationsTool(_dataService),
          ],
        );
    }

    // Create GenUiConversation
    _genUiConversation = GenUiConversation(
      a2uiMessageProcessor: _a2uiMessageProcessor,
      contentGenerator: contentGenerator,
      onSurfaceAdded: _onSurfaceAdded,
      onSurfaceDeleted: _onSurfaceDeleted,
      onError: _onError,
    );

    setState(() {
      _isInitialized = true;
    });
  }

  String _getSystemPrompt() {
    return '''
你是一位专业的智能投资顾问，名字叫"核心投顾"。

**CRITICAL: 你必须使用UI组件来展示信息，而不是纯文本回复。**

## 强制规则

1. **每次回复都必须调用 surfaceUpdate 和 beginRendering 创建UI**
2. **优先使用可视化组件，文字说明作为补充**
3. **获取数据后立即创建对应的UI组件**

## 可用工具

数据获取工具：
- get_portfolio: 获取用户投资组合
- get_stock_data(stockCode, timeRange): 获取股票数据
- analyze_risk: 分析投资风险
- get_recommendations(riskPreference, investmentGoal): 获取推荐

## 可用UI组件（必须使用）

- RiskAssessmentCard: 风险评估卡片
  - 必需字段: riskLevel, riskScore
  - 可选: volatility, diversification, suggestionsText
  
- TradeRecommendation: 交易推荐卡片
  - 必需字段: action, stockCode, stockName, reason
  - 可选: targetPrice, currentPrice, confidence, timeHorizon

## 交互规则

**初次对话时的标准流程：**
1. 调用 get_portfolio 获取投资组合数据
2. 调用 analyze_risk 获取风险分析
3. 使用 surfaceUpdate 创建包含以下组件的surface:
   - RiskAssessmentCard显示风险评估
4. 调用 beginRendering 渲染surface
5. 提供简短文字说明（不超过2句话）

**查看股票时：**
1. 调用 get_stock_data
2. 由于StockChart暂时不可用，用TradeRecommendation展示分析
3. 提供技术分析文字

**投资建议时：**
1. 调用 get_recommendations
2. 为每个推荐创建一个 TradeRecommendation 组件
3. 用 Column 组合多个组件

## 示例响应模式

用户: "我的投资组合情况如何？"

正确做法：
1. 调用 get_portfolio
2. 调用 analyze_risk  
3. 创建surface with RiskAssessmentCard
4. 简短文字："已为您展示投资组合风险评估"

错误做法：
❌ 只返回文本描述数据

记住：**永远不要只用文字，必须创建UI组件！**
''';
  }

  void _onSurfaceAdded(SurfaceAdded update) {
    setState(() {
      _surfaceIds.add(update.surfaceId);
    });
  }

  void _onSurfaceDeleted(SurfaceRemoved update) {
    setState(() {
      _surfaceIds.remove(update.surfaceId);
    });
  }

  void _onError(ContentGeneratorError error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('错误: ${error.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    _genUiConversation.sendRequest(UserMessage.text(text));
    _textController.clear();
  }

  @override
  void dispose() {
    _textController.dispose();
    _genUiConversation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Welcome banner (shown only when no surfaces)
        if (_surfaceIds.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(Icons.waving_hand, color: Colors.white, size: 48),
                SizedBox(height: 12),
                Text(
                  '您好！我是您的智能投资顾问',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '我可以帮您分析投资组合、评估风险、提供投资建议',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  '试试问我：\n• "我的投资组合情况如何？"\n• "帮我评估一下风险"\n• "给我一些投资建议"',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

        // Surfaces list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: _surfaceIds.length,
            itemBuilder: (context, index) {
              final String id = _surfaceIds[index];
              return GenUiSurface(host: _genUiConversation.host, surfaceId: id);
            },
          ),
        ),

        // Input field
        SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: '输入您的问题...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  onPressed: () => _sendMessage(_textController.text),
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
