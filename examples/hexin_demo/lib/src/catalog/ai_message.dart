// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Schema for AI message component.
///
/// DSL Example:
/// ```json
/// {
///   "type": "ai_message",
///   "props": {
///     "info": "截至09:28的股市焦点"
///   }
/// }
/// ```
final _aiMessageSchema = S.object(
  description: 'AI 助手消息气泡，显示 AI 生成的简短信息',
  properties: {
    'info': S.string(description: 'AI 消息内容'),
    'avatar': S.string(description: '头像 URL 或 asset 路径（可选）'),
    'name': S.string(description: 'AI 助手名称（可选，默认为 aimi）'),
  },
  required: ['info'],
);

/// AI message bubble component.
///
/// Displays an AI assistant message with avatar and info text.
/// Based on the design showing "aimi 为您提炼了截止09:28的股市重点".
final aiMessage = CatalogItem(
  name: 'ai_message',
  dataSchema: _aiMessageSchema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "ai_message": {
              "info": "截至09:28的股市焦点",
              "name": "aimi"
            }
          }
        }
      ]
    ''',
    () => '''
      [
        {
          "id": "root",
          "component": {
            "ai_message": {
              "info": "为您提炼了今日市场重点",
              "name": "智能助手"
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final String info = data['info'] as String? ?? '';
    final String? avatar = data['avatar'] as String?;
    final String name = data['name'] as String? ?? 'aimi';

    return _AiMessageBubble(info: info, avatar: avatar, name: name);
  },
);

class _AiMessageBubble extends StatelessWidget {
  const _AiMessageBubble({required this.info, this.avatar, required this.name});

  final String info;
  final String? avatar;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8C00), Color(0xFFFF6B00)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8C00).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: avatar != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      avatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                    ),
                  )
                : _buildDefaultAvatar(),
          ),
          const SizedBox(width: 10),
          // Name and Info
          Flexible(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: '$name ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: info),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'A',
        style: const TextStyle(
          color: Color(0xFFFF8C00),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
