// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Schema for section header component.
///
/// DSL Example:
/// ```json
/// {
///   "type": "sectionHeader",
///   "props": {
///     "title": "大盘统计",
///     "action": {
///       "type": "image",
///       "imageUrl": "https://xxx/ai_badge.png",
///       "text": "AI 深度解读",
///       "route": "client://ai.route/..."
///     }
///   }
/// }
/// ```
final _sectionHeaderSchema = S.object(
  description: '区块头部组件，显示标题和可选操作按钮',
  properties: {
    'title': S.string(description: '标题文本'),
    'action': S.object(
      description: '右侧操作按钮配置',
      properties: {
        'type': S.string(description: '按钮类型：text | image'),
        'text': S.string(description: '按钮文字'),
        'imageUrl': S.string(description: '图片 URL（type=image 时使用）'),
        'route': S.string(description: '点击跳转路由'),
      },
    ),
  },
  required: ['title'],
);

/// Section header component.
final sectionHeader = CatalogItem(
  name: 'sectionHeader',
  dataSchema: _sectionHeaderSchema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "sectionHeader": {
              "title": "大盘统计",
              "action": {
                "type": "image",
                "text": "AI 深度解读",
                "route": "client://ai.route/market"
              }
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final String title = data['title'] as String? ?? '';
    final Map<String, Object?>? action =
        data['action'] as Map<String, Object?>?;

    return _SectionHeader(
      title: title,
      action: action != null
          ? _ActionConfig(
              type: action['type'] as String? ?? 'text',
              text: action['text'] as String?,
              imageUrl: action['imageUrl'] as String?,
              route: action['route'] as String?,
            )
          : null,
      onActionTap: (route) {
        if (route != null) {
          context.dispatchEvent(
            UserActionEvent(
              name: 'navigate',
              sourceComponentId: context.id,
              context: {'route': route},
            ),
          );
        }
      },
    );
  },
);

class _ActionConfig {
  const _ActionConfig({
    required this.type,
    this.text,
    this.imageUrl,
    this.route,
  });

  final String type;
  final String? text;
  final String? imageUrl;
  final String? route;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onActionTap});

  final String title;
  final _ActionConfig? action;
  final void Function(String? route)? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Action button
          if (action != null) _buildAction(),
        ],
      ),
    );
  }

  Widget _buildAction() {
    return GestureDetector(
      onTap: () => onActionTap?.call(action!.route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6B8EFF), Color(0xFFB06BFF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AI icon
            if (action!.type == 'image') ...[
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Text(
                    'AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
            // Text
            if (action!.text != null)
              Text(
                action!.text!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
