// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import '../catalog/catalog.dart';
import '../services/custom_content_generator.dart';
import '../services/streaming_gen_ui_conversation.dart';
import '../widgets/conversation.dart';

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
    // For this demo, we default to CustomContentGenerator as configured in pubspec
    // and available services.
    final contentGenerator = CustomContentGenerator(
      baseUrl:
          'https://api.example.com/v1/chat/completions', // Replace with real config
      apiKey: 'config_api_key', // Replace with real config
      model: 'model_name',
      systemInstruction: _getSystemPrompt(),
      catalog: hexinCatalog,
    );

    _uiConversation = StreamingGenUiConversation(
      a2uiMessageProcessor: a2uiMessageProcessor,
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
You are Hexin, an intelligent investment advisor assistant.
Your goal is to help users analyze the market, manage portfolios, and make investment decisions.

**CRITICAL: You must use UI components to display information whenever possible.**

## Usage Rules
1. Call `surfaceUpdate` and `beginRendering` to create UI.
2. Prioritize visual components over text.
3. Use data fetching tools to get real-time info.

## Available Desired Components
- RiskAssessmentCard
- TradeRecommendation
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
