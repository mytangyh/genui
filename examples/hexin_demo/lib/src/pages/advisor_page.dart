// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import '../catalog/catalog.dart';
import '../services/custom_content_generator.dart';
import '../services/system_prompts.dart';
import 'package:hexin_general_chat/hexin_general_chat.dart';

class AdvisorPage extends StatefulWidget {
  const AdvisorPage({super.key});

  @override
  State<AdvisorPage> createState() => _AdvisorPageState();
}

class _AdvisorPageState extends State<AdvisorPage>
    with AutomaticKeepAliveClientMixin {
  StreamingGenUiConversation? _uiConversation;
  StreamSubscription<ChatMessage>? _userMessageSubscription;

  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  /// 当前交易时段
  late MarketSession _currentSession;

  Catalog get hexinCatalog => FinancialCatalog.getCatalog();

  @override
  void initState() {
    super.initState();
    // 检测当前时段
    _currentSession = detectMarketSession();
    _initConversation();
  }

  /// 初始化对话（切换场景时重新调用）
  Future<void> _initConversation() async {
    // 清理旧实例
    _userMessageSubscription?.cancel();
    _uiConversation?.dispose();

    final a2uiMessageProcessor = A2uiMessageProcessor(catalogs: [hexinCatalog]);

    _userMessageSubscription = a2uiMessageProcessor.onSubmit.listen(
      _handleUserMessageFromUi,
    );

    // 根据场景获取 System Prompt
    final systemPrompt = SystemPrompts.forSession(_currentSession);

    // Initialize content generator with session-specific prompt
    final contentGenerator = CustomContentGenerator(
      baseUrl: 'https://integrate.api.nvidia.com/v1/chat/completions',
      apiKey:
          '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',
      model: 'z-ai/glm4.7',
      systemInstruction: systemPrompt,
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

    if (mounted) setState(() {});
  }

  /// 切换交易时段
  void _switchSession(MarketSession session) {
    if (_currentSession == session) return;
    setState(() {
      _currentSession = session;
    });
    _initConversation();
  }

  @override
  void dispose() {
    _userMessageSubscription?.cancel();
    _uiConversation?.dispose();
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
    final conv = _uiConversation;
    if (conv == null) return;
    if (conv.isProcessing.value || text.trim().isEmpty) return;
    _scrollToBottom();
    _textController.clear();
    conv.sendRequest(UserMessage.text(text));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final conv = _uiConversation;
    if (conv == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: Column(
        children: [
          // 场景指示器
          _SessionIndicator(
            currentSession: _currentSession,
            onSessionChanged: _switchSession,
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: ValueListenableBuilder<List<ChatMessage>>(
                  valueListenable: conv.conversation,
                  builder: (context, messages, child) {
                    return Conversation(
                      messages: messages,
                      manager: conv.a2uiMessageProcessor,
                      scrollController: _scrollController,
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ValueListenableBuilder<bool>(
              valueListenable: conv.isProcessing,
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

/// 场景指示器组件
class _SessionIndicator extends StatelessWidget {
  const _SessionIndicator({
    required this.currentSession,
    required this.onSessionChanged,
  });

  final MarketSession currentSession;
  final ValueChanged<MarketSession> onSessionChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: MarketSession.values.map((session) {
          final isSelected = session == currentSession;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(_getSessionLabel(session)),
              selected: isSelected,
              onSelected: (_) => onSessionChanged(session),
              avatar: isSelected
                  ? Icon(
                      _getSessionIcon(session),
                      size: 18,
                    )
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getSessionLabel(MarketSession session) {
    switch (session) {
      case MarketSession.preMarket:
        return '盘前';
      case MarketSession.intraday:
        return '盘中';
      case MarketSession.postMarket:
        return '盘后';
    }
  }

  IconData _getSessionIcon(MarketSession session) {
    switch (session) {
      case MarketSession.preMarket:
        return Icons.wb_sunny_outlined;
      case MarketSession.intraday:
        return Icons.trending_up;
      case MarketSession.postMarket:
        return Icons.nightlight_outlined;
    }
  }
}
