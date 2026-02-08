// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import '../catalog/catalog.dart';
import '../services/custom_content_generator.dart';
import 'package:hexin_general_chat/hexin_general_chat.dart';

class AdvisorPage extends StatefulWidget {
  const AdvisorPage({super.key});

  @override
  State<AdvisorPage> createState() => _AdvisorPageState();
}

class _AdvisorPageState extends State<AdvisorPage>
    with AutomaticKeepAliveClientMixin {
  late final StreamingGenUiConversation _uiConversation;
  late final StreamSubscription<ChatMessage> _userMessageSubscription;

  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  Catalog get hexinCatalog => FinancialCatalog.getCatalog();

  @override
  void initState() {
    super.initState();

    final a2uiMessageProcessor = A2uiMessageProcessor(catalogs: [hexinCatalog]);

    _userMessageSubscription = a2uiMessageProcessor.onSubmit.listen(
      _handleUserMessageFromUi,
    );

    // Initialize content generator
    // Using NVIDIA API with GLM-4 model
    final contentGenerator = CustomContentGenerator(
      baseUrl: 'https://integrate.api.nvidia.com/v1/chat/completions',
      apiKey:
          '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',
      model: 'z-ai/glm4.7',
      systemInstruction: _getSystemPrompt(),
      catalog: hexinCatalog,
    );

    _uiConversation = StreamingGenUiConversation(
      a2uiMessageProcessor: a2uiMessageProcessor,
      contentGenerator: contentGenerator,
      onSurfaceUpdated: (update) {
        debugPrint(
            'DEBUG: onSurfaceUpdated callback triggered: ${update.surfaceId}');
        _scrollToBottom();
      },
      onSurfaceAdded: (update) {
        debugPrint(
            'DEBUG: onSurfaceAdded callback triggered: ${update.surfaceId}');
        _scrollToBottom();
      },
      onTextResponse: (text) {
        if (!mounted) return;
        if (text.isNotEmpty) {
          _scrollToBottom();
        }
      },
    );
  }

  @override
  void dispose() {
    _userMessageSubscription.cancel();
    _uiConversation.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _handleUserMessageFromUi(ChatMessage message) {
    _scrollToBottom();
  }

  void _sendPrompt(String text) {
    if (_uiConversation.isProcessing.value || text.trim().isEmpty) return;
    _scrollToBottom();
    _textController.clear();
    _uiConversation.sendRequest(UserMessage.text(text));
  }

  String _getSystemPrompt() {
    return '''
# 角色设定

你是 Hexin Flow（同花顺·流）智能投资顾问。通过 UI 组件与用户交流。

# 重要规则

1. 必须调用 uiGenerationTool 生成 UI
2. 每次只使用**一个简单组件**，避免复杂嵌套
3. components 数组中必须有一个 id 为 "root" 的组件

# 常用组件示例

## infoSummaryCard - 用于摘要信息（推荐使用）
```json
{"surfaceId":"info_001","components":[{"id":"root","component":{"infoSummaryCard":{"title":"标题","summary":"内容摘要"}}}]}
```

## StockQuote - 用于股票行情（注意大写S）
```json
{"surfaceId":"stock_001","components":[{"id":"root","component":{"StockQuote":{"stockName":"贵州茅台","stockCode":"600519","price":1850.00,"change":2.35}}}]}
```

## ai_message - 用于详细分析（注意下划线）
```json
{"surfaceId":"analysis_001","components":[{"id":"root","component":{"ai_message":{"info":"分析摘要内容..."}}}]}
```

# 用户数据

持仓：茅台100股(+2.78%)、比亚迪500股(+14.29%)、平安200股(-6.67%)
总资产：50万，收益率+5.2%
''';
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
                    return Conversation(
                      messages: messages,
                      manager: _uiConversation.a2uiMessageProcessor,
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
                builder: (context, isProcessing, child) {
                  return _ChatInput(
                    controller: _textController,
                    isThinking: isProcessing,
                    onSend: _sendPrompt,
                  );
                },
              ),
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
                  hintText: '输入您的投资问题...',
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
