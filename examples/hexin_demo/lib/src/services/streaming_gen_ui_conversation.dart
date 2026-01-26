// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';

/// A custom copy of GenUiConversation to support correct text streaming behavior.
///
/// This class handles textResponseStream by appending text to the last message
/// instead of creating new messages for each chunk.
class StreamingGenUiConversation {
  /// Creates a new [StreamingGenUiConversation].
  StreamingGenUiConversation({
    this.onSurfaceAdded,
    this.onSurfaceUpdated,
    this.onSurfaceDeleted,
    this.onTextResponse,
    this.onError,
    required this.contentGenerator,
    required this.genUiManager,
  }) {
    _a2uiSubscription = contentGenerator.a2uiMessageStream.listen(
      genUiManager.handleMessage,
    );
    _userEventSubscription = genUiManager.onSubmit.listen(sendRequest);
    _surfaceUpdateSubscription = genUiManager.surfaceUpdates.listen(
      _handleSurfaceUpdate,
    );
    _textResponseSubscription = contentGenerator.textResponseStream.listen(
      _handleTextResponse,
    );
    _errorSubscription = contentGenerator.errorStream.listen(_handleError);
  }

  /// The [ContentGenerator] for the conversation.
  final ContentGenerator contentGenerator;

  /// The manager for the UI surfaces in the conversation.
  final GenUiManager genUiManager;

  /// A callback for when a new surface is added by the AI.
  final ValueChanged<SurfaceAdded>? onSurfaceAdded;

  /// A callback for when a surface is deleted by the AI.
  final ValueChanged<SurfaceRemoved>? onSurfaceDeleted;

  /// A callback for when a surface is updated by the AI.
  final ValueChanged<SurfaceUpdated>? onSurfaceUpdated;

  /// A callback for when a text response is received from the AI.
  final ValueChanged<String>? onTextResponse;

  /// A callback for when an error occurs in the content generator.
  final ValueChanged<ContentGeneratorError>? onError;

  late final StreamSubscription<A2uiMessage> _a2uiSubscription;
  late final StreamSubscription<ChatMessage> _userEventSubscription;
  late final StreamSubscription<GenUiUpdate> _surfaceUpdateSubscription;
  late final StreamSubscription<String> _textResponseSubscription;
  late final StreamSubscription<ContentGeneratorError> _errorSubscription;

  final ValueNotifier<List<ChatMessage>> _conversation =
      ValueNotifier<List<ChatMessage>>([]);

  void _handleSurfaceUpdate(GenUiUpdate update) {
    switch (update) {
      case SurfaceAdded():
        _conversation.value = [
          ..._conversation.value,
          AiUiMessage(
            definition: update.definition,
            surfaceId: update.surfaceId,
          ),
        ];
        onSurfaceAdded?.call(update);
      case SurfaceUpdated():
        final newConversation = List<ChatMessage>.from(_conversation.value);
        final int index = newConversation.lastIndexWhere(
          (m) => m is AiUiMessage && m.surfaceId == update.surfaceId,
        );
        final newMessage = AiUiMessage(
          definition: update.definition,
          surfaceId: update.surfaceId,
        );
        if (index != -1) {
          newConversation[index] = newMessage;
        } else {
          newConversation.add(newMessage);
        }
        _conversation.value = newConversation;
        onSurfaceUpdated?.call(update);
      case SurfaceRemoved():
        final newConversation = List<ChatMessage>.from(_conversation.value);
        newConversation.removeWhere(
          (m) => m is AiUiMessage && m.surfaceId == update.surfaceId,
        );
        _conversation.value = newConversation;
        onSurfaceDeleted?.call(update);
    }
  }

  /// Disposes of the resources used by this agent.
  void dispose() {
    _a2uiSubscription.cancel();
    _userEventSubscription.cancel();
    _surfaceUpdateSubscription.cancel();
    _textResponseSubscription.cancel();
    _errorSubscription.cancel();
    contentGenerator.dispose();
    genUiManager.dispose();
  }

  /// The host for the UI surfaces managed by this agent.
  GenUiHost get host => genUiManager;

  /// A [ValueNotifier] that provides the current conversation history.
  ValueNotifier<List<ChatMessage>> get conversation => _conversation;

  /// A [ValueListenable] that indicates whether the agent is currently
  /// processing a request.
  ValueListenable<bool> get isProcessing => contentGenerator.isProcessing;

  /// Returns a [ValueNotifier] for the given [surfaceId].
  ValueNotifier<UiDefinition?> surface(String surfaceId) {
    return genUiManager.getSurfaceNotifier(surfaceId);
  }

  /// Sends a user message to the AI to generate a UI response.
  Future<void> sendRequest(ChatMessage message) async {
    final List<ChatMessage> history = _conversation.value;
    if (message is! UserUiInteractionMessage) {
      _conversation.value = [...history, message];
    }
    return contentGenerator.sendRequest(message, history: history);
  }

  /// PATCHED Method for Streaming
  void _handleTextResponse(String text) {
    if (text.isEmpty) return;

    final currentHistory = List<ChatMessage>.from(_conversation.value);
    final lastMessage = currentHistory.isNotEmpty ? currentHistory.last : null;

    if (lastMessage is AiTextMessage) {
      // Append to the last message
      final newText = lastMessage.text + text;
      currentHistory.last = AiTextMessage.text(newText);
    } else {
      // Start a new message
      currentHistory.add(AiTextMessage.text(text));
    }

    _conversation.value = currentHistory;
    onTextResponse?.call(text);
  }

  void _handleError(ContentGeneratorError error) {
    final errorResponseMessage = AiTextMessage.text(
      'An error occurred: ${error.error}',
    );
    _conversation.value = [..._conversation.value, errorResponseMessage];
    onError?.call(error);
  }
}
