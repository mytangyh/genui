// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:genui/genui.dart';

import 'markdown_message_widget.dart';

typedef UserPromptBuilder = Widget Function(
    BuildContext context, UserMessage message);

typedef UserUiInteractionBuilder = Widget Function(
    BuildContext context, UserUiInteractionMessage message);

/// A widget that displays a conversation with a generative AI.
class Conversation extends StatelessWidget {
  /// Creates a new [Conversation].
  const Conversation({
    super.key,
    required this.messages,
    required this.manager,
    required this.scrollController,
    this.userUiInteractionBuilder,
    this.showInternalMessages = false,
  });

  final List<ChatMessage> messages;
  final A2uiMessageProcessor manager;
  final ScrollController scrollController;
  final UserUiInteractionBuilder? userUiInteractionBuilder;
  final bool showInternalMessages;

  @override
  Widget build(BuildContext context) {
    // Hide internal messages unless requested.
    final renderedMessages = messages.where((m) {
      return showInternalMessages || m is! InternalMessage;
    }).toList();

    return ListView.builder(
      controller: scrollController,
      itemCount: renderedMessages.length,
      itemBuilder: (context, index) {
        final ChatMessage message = renderedMessages[index];
        return switch (message) {
          UserMessage() => ChatMessageView(
              text: message.text,
              icon: Icons.person,
              alignment: MainAxisAlignment.end,
            ),
          AiTextMessage() => message.text.trim().isEmpty
              ? const SizedBox.shrink()
              : MarkdownMessageWidget(
                  text: message.text,
                  icon: Icons.smart_toy_outlined,
                  alignment: MainAxisAlignment.start,
                ),
          AiUiMessage() => Padding(
              padding: const EdgeInsets.all(16.0),
              child: GenUiSurface(
                key: message.uiKey,
                host: manager,
                surfaceId: message.surfaceId,
              ),
            ),
          InternalMessage() => InternalMessageView(content: message.text),
          UserUiInteractionMessage() => userUiInteractionBuilder != null
              ? userUiInteractionBuilder!(context, message)
              : ChatMessageView(
                  text: message.text,
                  icon: Icons.touch_app,
                  alignment: MainAxisAlignment.end,
                ),
          ToolResponseMessage() =>
            // Tool responses are typically internal, but if shown, just show text count/summary
            InternalMessageView(
              content: 'Tool Result: ${message.results.length} items',
            ),
        };
      },
    );
  }
}
