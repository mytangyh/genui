// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'package:genui/genui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to save and load chat history.
class ChatHistoryService {
  static const String _keyChatHistory = 'chat_history';

  /// Saves the chat history to shared preferences.
  Future<void> saveHistory(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = messages.map(_messageToJson).toList();
    await prefs.setString(_keyChatHistory, jsonEncode(jsonList));
  }

  /// Loads the chat history from shared preferences.
  Future<List<ChatMessage>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyChatHistory);
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((e) => _messageFromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading chat history: $e');
      return [];
    }
  }

  /// Clears the chat history.
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyChatHistory);
  }

  // --- Serialization Logic ---

  Map<String, dynamic> _messageToJson(ChatMessage message) {
    switch (message) {
      case UserMessage():
        return {
          'type': 'UserMessage',
          'parts': message.parts.map(_partToJson).toList(),
        };
      case AiTextMessage():
        return {
          'type': 'AiTextMessage',
          'parts': message.parts.map(_partToJson).toList(),
        };
      case AiUiMessage():
        return {
          'type': 'AiUiMessage',
          'uiDefinition': message.definition.toJson(),
          'surfaceId': message.surfaceId,
        };
      // Skip InternalMessage, ToolResponseMessage, UserUiInteractionMessage for simple history
      default:
        return {'type': 'unknown'};
    }
  }

  ChatMessage _messageFromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'UserMessage':
        final parts = (json['parts'] as List)
            .map((e) => _partFromJson(e as Map<String, dynamic>))
            .toList();
        return UserMessage(parts);
      case 'AiTextMessage':
        final parts = (json['parts'] as List)
            .map((e) => _partFromJson(e as Map<String, dynamic>))
            .toList();
        return AiTextMessage(parts);
      case 'AiUiMessage':
        final uiDefJson = json['uiDefinition'] as Map<String, dynamic>;
        final surfaceId = json['surfaceId'] as String;

        // Reconstruct UiDefinition
        final componentsJson = uiDefJson['components'] as Map<String, dynamic>;
        final components = componentsJson.map((key, value) {
          return MapEntry(
              key, Component.fromJson(value as Map<String, dynamic>));
        });

        final definition = UiDefinition(
          surfaceId: uiDefJson['surfaceId'] as String,
          rootComponentId: uiDefJson['rootComponentId'] as String?,
          components: components,
        );

        return AiUiMessage(definition: definition, surfaceId: surfaceId);
      default:
        // Return a safe placeholder for unknown/unsupported messages
        return AiTextMessage.text('(Unsupported message type from history)');
    }
  }

  Map<String, dynamic> _partToJson(MessagePart part) {
    switch (part) {
      case TextPart():
        return {'type': 'TextPart', 'text': part.text};
      // Implement other parts if needed
      default:
        return {'type': 'unknown'};
    }
  }

  MessagePart _partFromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'TextPart':
        return TextPart(json['text'] as String);
      default:
        return const TextPart('(Unknown part)');
    }
  }
}
