// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Schema for button list component.
///
/// DSL Example:
/// ```json
/// {
///   "type": "ai_buttonList",
///   "props": {
///     "buttons": [
///       {"text": "今天炒什么", "icon": "whatshot", "route": "client://ai.route/today"},
///       {"text": "昨日涨停表现", "icon": "trending_up", "route": "client://ai.route/yesterday"}
///     ]
///   }
/// }
/// ```
final _aiButtonListSchema = S.object(
  description: 'AI 按钮组，显示一排可点击的按钮',
  properties: {
    'buttons': ListSchema(
      description: '按钮列表',
      items: S.object(
        properties: {
          'text': S.string(description: '按钮文字'),
          'icon': S.string(description: 'Flutter 图标名称（可选）'),
          'route': S.string(description: '点击跳转路由'),
        },
        required: ['text', 'route'],
      ),
    ),
    'spacing': S.number(description: '按钮间距（可选，默认12）'),
  },
  required: ['buttons'],
);

/// AI button list component.
///
/// Displays a horizontal row of buttons with icons.
/// Based on the design showing "今天炒什么" and "昨日涨停表现" buttons.
final aiButtonList = CatalogItem(
  name: 'ai_buttonList',
  dataSchema: _aiButtonListSchema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "ai_buttonList": {
              "buttons": [
                {"text": "今天炒什么", "icon": "whatshot", "route": "client://ai.route/today"},
                {"text": "昨日涨停表现", "icon": "trending_up", "route": "client://ai.route/yesterday"}
              ]
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final List<dynamic> buttons = data['buttons'] as List<dynamic>? ?? [];
    final num spacing = data['spacing'] as num? ?? 12;

    return _AiButtonList(
      buttons: buttons.map((btn) {
        final Map<String, Object?> btnData = btn as Map<String, Object?>;
        return _ButtonData(
          text: btnData['text'] as String? ?? '',
          icon: btnData['icon'] as String?,
          route: btnData['route'] as String? ?? '',
        );
      }).toList(),
      spacing: spacing.toDouble(),
      onButtonTap: (route) {
        context.dispatchEvent(
          UserActionEvent(
            name: 'navigate',
            sourceComponentId: context.id,
            context: {'route': route},
          ),
        );
      },
    );
  },
);

class _ButtonData {
  const _ButtonData({required this.text, this.icon, required this.route});

  final String text;
  final String? icon;
  final String route;
}

class _AiButtonList extends StatelessWidget {
  const _AiButtonList({
    required this.buttons,
    this.spacing = 12,
    this.onButtonTap,
  });

  final List<_ButtonData> buttons;
  final double spacing;
  final void Function(String route)? onButtonTap;

  /// Maps icon name strings to Flutter icons.
  IconData _getIcon(String? iconName) {
    if (iconName == null) return Icons.star_outline;

    switch (iconName.toLowerCase()) {
      case 'whatshot':
        return Icons.whatshot;
      case 'trending_up':
        return Icons.trending_up;
      case 'trending_down':
        return Icons.trending_down;
      case 'star':
        return Icons.star;
      case 'search':
        return Icons.search;
      case 'analytics':
        return Icons.analytics;
      case 'insights':
        return Icons.insights;
      case 'lightbulb':
        return Icons.lightbulb_outline;
      case 'recommend':
        return Icons.recommend;
      case 'auto_graph':
        return Icons.auto_graph;
      case 'pets':
        return Icons.pets;
      default:
        return Icons.star_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: spacing,
        runSpacing: 8,
        children: buttons.map((button) => _buildButton(button)).toList(),
      ),
    );
  }

  Widget _buildButton(_ButtonData button) {
    return GestureDetector(
      onTap: () => onButtonTap?.call(button.route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2A3D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon placeholder (left side)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFFF8C00).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIcon(button.icon),
                size: 14,
                color: const Color(0xFFFF8C00),
              ),
            ),
            const SizedBox(width: 8),
            // Button text
            Text(
              button.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
