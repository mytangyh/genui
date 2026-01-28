// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:hexin_ai_ui/hexin_ai_ui.dart';

import '../services/chat_history_service.dart';
import '../services/settings_service.dart';
import '../services/sse_content_generator.dart';
import '../services/streaming_gen_ui_conversation.dart';
import '../widgets/conversation.dart';
import 'chat_settings_page.dart';

class GeneralChatPage extends StatefulWidget {
  const GeneralChatPage({super.key});

  @override
  State<GeneralChatPage> createState() => _GeneralChatPageState();
}

class _GeneralChatPageState extends State<GeneralChatPage> {
  late final StreamingGenUiConversation _uiConversation;
  late final StreamSubscription<ChatMessage> _userMessageSubscription;
  late final String _selectedModel;

  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  final _settingsService = SettingsService();
  final _historyService = ChatHistoryService();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final settings = await _settingsService.loadSettings();
    if (settings == null) {
      if (mounted) {
        await _navigateToSettings();
      }
    } else {
      _setupConversation(settings);
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    final history = await _historyService.loadHistory();
    if (history.isNotEmpty) {
      _uiConversation.conversation.value = history;
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  Future<void> _navigateToSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute<bool>(builder: (context) => const ChatSettingsPage()),
    );

    // If settings were saved (result == true) or we just came back, try to reload.
    // Ideally we only reload if saved.
    if (result == true) {
      _initialize();
    } else {
      // user mocked back without saving, if we have no settings, we can't do anything.
      final settings = await _settingsService.loadSettings();
      if (settings == null) {
        if (mounted) Navigator.pop(context); // Go back to entry page
      }
    }
  }

  void _setupConversation(Map<String, String> settings) {
    _selectedModel = settings['model']!;

    // Catalog
    final catalog = Catalog([
      ...CoreCatalogItems.asCatalog().items,
      ...AiUiCatalog.getAllItems(), // Use AiUiCatalog directly
    ]);

    final a2uiMessageProcessor = A2uiMessageProcessor(catalogs: [catalog]);

    _userMessageSubscription = a2uiMessageProcessor.onSubmit.listen(
      _handleUserMessageFromUi,
    );
    final contentGenerator = SSEContentGenerator(
      baseUrl: settings['baseUrl']!,
      apiKey: settings['apiKey']!,
      model: settings['model']!,
      catalog: catalog,
      systemInstruction:
          'You are a helpful AI assistant. You can use UI tools if applicable.',
    );

    _uiConversation = StreamingGenUiConversation(
      a2uiMessageProcessor: a2uiMessageProcessor,
      contentGenerator: contentGenerator,
      onSurfaceUpdated: (_) {
        _scrollToBottom();
        _saveHistory();
      },
      onSurfaceAdded: (_) {
        _scrollToBottom();
        _saveHistory(); // Save on new surface
      },
      onTextResponse: (text) {
        if (mounted && text.isNotEmpty) _scrollToBottom();
        _saveHistory(); // Save on streaming text
      },
      onError: _onError,
    );

    // Listen to conversation changes for other message types (UserMessage)
    _uiConversation.conversation.addListener(_onConversationChanged);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onConversationChanged() {
    _saveHistory();
  }

  void _saveHistory() {
    _historyService.saveHistory(_uiConversation.conversation.value);
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

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (_uiConversation.isProcessing.value) return;

    _textController.clear();
    _scrollToBottom();
    await _uiConversation.sendRequest(UserMessage.text(text));
  }

  void _onError(ContentGeneratorError error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: ${error.error}'),
            backgroundColor: Colors.red),
      );
    }
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedModel),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
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
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ValueListenableBuilder<bool>(
        valueListenable: _uiConversation.isProcessing,
        builder: (context, isProcessing, child) {
          return Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  enabled: !isProcessing,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: isProcessing ? null : _sendMessage,
                ),
              ),
              const SizedBox(width: 8),
              if (isProcessing)
                const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_textController.text),
                ),
            ],
          );
        },
      ),
    );
  }
}
