// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Schema for "Conversation Card" component.
///
/// DSL Example:
/// ```json
/// {
///   "type": "conversationCard",
///   "props": {
///     "onOrderTap": "client://trade/order",
///     "onMicTap": "client://voice/start",
///     "onKeyboardTap": "client://keyboard/open"
///   }
/// }
/// ```
final _conversationCardSchema = S.object(
  description: '对话卡片，包含下单、语音、键盘三个按钮',
  properties: {
    'onOrderTap': S.string(description: '点击下单按钮的路由'),
    'onMicTap': S.string(description: '点击语音按钮的路由'),
    'onKeyboardTap': S.string(description: '点击键盘按钮的路由'),
  },
);

/// Conversation card component.
final conversationCard = CatalogItem(
  name: 'conversationCard',
  dataSchema: _conversationCardSchema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "conversationCard": {
              "onOrderTap": "client://trade/order",
              "onMicTap": "client://voice/start",
              "onKeyboardTap": "client://keyboard/open"
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final onOrderTap = data['onOrderTap'] as String?;
    final onMicTap = data['onMicTap'] as String?;
    final onKeyboardTap = data['onKeyboardTap'] as String?;

    return _ConversationCard(
      onAction: (name, route) {
        if (route != null) {
          context.dispatchEvent(
            UserActionEvent(
              name: name,
              sourceComponentId: context.id,
              context: {'route': route},
            ),
          );
        }
      },
      orderRoute: onOrderTap,
      micRoute: onMicTap,
      keyboardRoute: onKeyboardTap,
    );
  },
);

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.onAction,
    this.orderRoute,
    this.micRoute,
    this.keyboardRoute,
  });

  final void Function(String name, String? route) onAction;
  final String? orderRoute;
  final String? micRoute;
  final String? keyboardRoute;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF191919), // Match provided image bg
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Order Button
              _buildBadgedButton(
                onTap: () => onAction('order_tap', orderRoute),
                child: const Center(
                  child: Text(
                    '下单',
                    style: TextStyle(
                      color: Color(0xFFFF4D4F),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                badgeIcon: Icons.swap_horiz,
              ),

              const SizedBox(width: 12),

              // Center: Mic Button
              Expanded(
                child: GestureDetector(
                  onTap: () => onAction('mic_tap', micRoute),
                  child: Container(
                    height: 54,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2BCCFF), Color(0xFF9B6BFF)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(27)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mic, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text(
                          '按住说话',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Right: Keyboard Button
              _buildBadgedButton(
                onTap: () => onAction('keyboard_tap', keyboardRoute),
                child: const Center(
                  child: Icon(Icons.keyboard, color: Colors.white, size: 24),
                ),
                badgeIcon: Icons.search,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '以上部分内容由AI生成，不构成投资建议',
            style: TextStyle(
              color: Color(0xFF666666),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgedButton({
    required Widget child,
    required IconData badgeIcon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 58,
        height: 52,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Main Circle
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2BCCFF),
                  width: 1.5,
                ),
              ),
              child: child,
            ),
            // Badge
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Color(0xFF191919), // Bg matches card
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(1), // Border effect
                child:
                    Icon(badgeIcon, size: 16, color: const Color(0xFF2BCCFF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
