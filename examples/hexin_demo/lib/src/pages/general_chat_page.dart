// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import '../catalog/catalog.dart';
import '../services/settings_service.dart';
import '../services/sse_content_generator.dart';
import '../services/chat_history_service.dart';
import '../widgets/conversation.dart';
import '../services/streaming_gen_ui_conversation.dart';
import 'chat_settings_page.dart';

class GeneralChatPage extends StatefulWidget {
  const GeneralChatPage({super.key});

  @override
  State<GeneralChatPage> createState() => _GeneralChatPageState();
}

class _GeneralChatPageState extends State<GeneralChatPage> {
  final _settingsService = SettingsService();
  final _historyService = ChatHistoryService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  StreamingGenUiConversation? _uiConversation;
  StreamSubscription<ChatMessage>? _userMessageSubscription;
  bool _isLoading = true;
  String? _currentModel;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);

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
    if (history.isNotEmpty && _uiConversation != null) {
      _uiConversation!.conversation.value = history;
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
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setupConversation(Map<String, String> settings) {
    _currentModel = settings['model'];

    // Dispose previous conversation if any
    _uiConversation?.dispose();
    _userMessageSubscription?.cancel();

    // Catalog
    final catalog = Catalog([
      ...CoreCatalogItems.asCatalog().items,
      ...FinancialCatalog.getCatalog().items, // giving it full power
    ]);

    final genUiManager = GenUiManager(
      catalog: catalog,
      configuration: const GenUiConfiguration(
        actions: ActionsConfig(allowCreate: true, allowUpdate: true),
      ),
    );

    _userMessageSubscription =
        genUiManager.onSubmit.listen(_handleUserMessageFromUi);

    final contentGenerator = SSEContentGenerator(
      baseUrl: settings['baseUrl']!,
      apiKey: settings['apiKey']!,
      model: settings['model']!,
      catalog: catalog,
      systemInstruction:
          'You are a helpful AI assistant. You can use UI tools if applicable.',
    );

    _uiConversation = StreamingGenUiConversation(
      genUiManager: genUiManager,
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
    _uiConversation!.conversation.addListener(_onConversationChanged);

    setState(() => _isLoading = false);
  }

  void _onConversationChanged() {
    _saveHistory();
  }

  void _saveHistory() {
    if (_uiConversation != null) {
      _historyService.saveHistory(_uiConversation!.conversation.value);
    }
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
    if (_uiConversation == null || text.trim().isEmpty) return;
    if (_uiConversation!.isProcessing.value) return;

    _textController.clear();
    _scrollToBottom();
    await _uiConversation!.sendRequest(UserMessage.text(text));
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
    _uiConversation?.conversation.removeListener(_onConversationChanged);
    _uiConversation?.dispose();
    _userMessageSubscription?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Safety check in case initialization failed but loading stopped
    if (_uiConversation == null) {
      return const Scaffold(body: Center(child: Text('Initialization failed')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentModel ?? 'Chat'),
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
              valueListenable: _uiConversation!.conversation,
              builder: (context, messages, child) {
                return Conversation(
                  messages: messages,
                  manager: _uiConversation!.genUiManager,
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
        valueListenable: _uiConversation!.isProcessing,
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
