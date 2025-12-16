// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:genui_google_generative_ai/genui_google_generative_ai.dart';

import '../catalog/catalog.dart';
import '../config/configuration.dart';
import '../services/mock_data_service.dart';
import '../tools/analyze_risk_tool.dart';
import '../tools/get_portfolio_tool.dart';
import '../tools/get_recommendations_tool.dart';
import '../tools/get_stock_data_tool.dart';
import '../widgets/conversation.dart';

/// Main advisor page for hexin_demo.
class AdvisorPage extends StatefulWidget {
  const AdvisorPage({super.key});

  @override
  State<AdvisorPage> createState() => _AdvisorPageState();
}

class _AdvisorPageState extends State<AdvisorPage>
    with AutomaticKeepAliveClientMixin {
  late final GenUiConversation _uiConversation;
  late final StreamSubscription<ChatMessage> _userMessageSubscription;
  late final MockDataService _dataService;

  final _textController = TextEditingController();
  final _scrollController = ScrollController();

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

    // Create GenUiManager with catalog
    final genUiManager = GenUiManager(
      catalog: catalog,
      configuration: const GenUiConfiguration(
        actions: ActionsConfig(
          allowCreate: true,
          allowUpdate: true,
          allowDelete: true,
        ),
      ),
    );

    _userMessageSubscription = genUiManager.onSubmit.listen(
      _handleUserMessageFromUi,
    );

    // Create ContentGenerator based on configuration
    final ContentGenerator contentGenerator;

    switch (aiBackend) {
      case AiBackend.firebase:
        // Firebase backend not implemented in this demo
        throw UnimplementedError(
          'Firebase AI backend is not configured. '
          'Please use googleGenerativeAi backend.',
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

    // Create GenUiConversation with proper genUiManager parameter
    _uiConversation = GenUiConversation(
      genUiManager: genUiManager,
      contentGenerator: contentGenerator,
      onSurfaceUpdated: (update) {
        _scrollToBottom();
      },
      onSurfaceAdded: (update) {
        _scrollToBottom();
      },
      onTextResponse: (text) {
        if (!mounted) return;
        if (text.isNotEmpty) {
          _scrollToBottom();
        }
      },
      onError: _onError,
    );
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _triggerInference(ChatMessage message) async {
    await _uiConversation.sendRequest(message);
  }

  void _handleUserMessageFromUi(ChatMessage message) {
    _scrollToBottom();
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
    if (_uiConversation.isProcessing.value || text.trim().isEmpty) return;
    _scrollToBottom();
    _textController.clear();
    _triggerInference(UserMessage.text(text));
  }

  @override
  void dispose() {
    _userMessageSubscription.cancel();
    _uiConversation.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      child: Center(
        child: Column(
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: ValueListenableBuilder<List<ChatMessage>>(
                  valueListenable: _uiConversation.conversation,
                  builder: (context, messages, child) {
                    if (messages.isEmpty) {
                      return _buildWelcomeBanner();
                    }
                    return Conversation(
                      messages: messages,
                      manager: _uiConversation.genUiManager,
                      scrollController: _scrollController,
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ValueListenableBuilder<bool>(
                valueListenable: _uiConversation.isProcessing,
                builder: (context, isThinking, child) {
                  return _ChatInput(
                    controller: _textController,
                    isThinking: isThinking,
                    onSend: _sendMessage,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Center(
      child: Container(
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
          mainAxisSize: MainAxisSize.min,
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
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.isThinking,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isThinking;
  final void Function(String) onSend;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2.0,
      borderRadius: BorderRadius.circular(25.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isThinking,
                decoration: const InputDecoration.collapsed(
                  hintText: '输入您的问题...',
                ),
                onSubmitted: isThinking ? null : onSend,
              ),
            ),
            if (isThinking)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.0),
              )
            else
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => onSend(controller.text),
              ),
          ],
        ),
      ),
    );
  }
}
