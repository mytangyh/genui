// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Schema for news flash list component.
///
/// DSL Example:
/// ```json
/// {
///   "type": "newsFlashList",
///   "props": {
///     "title": "市场快讯",
///     "subtitle": "更新于08:08，更新了3条内容",
///     "items": [
///       {"text": "国产汽车芯片认证审查技术体系实现突破", "route": "..."},
///       {"text": "狂飙涨停潮！AI应用方向集体走高半导体板块…", "route": "..."}
///     ]
///   }
/// }
/// ```
final _newsFlashListSchema = S.object(
  description: '快讯列表组件，显示多条简短新闻快讯，带序号和渐变色',
  properties: {
    'title': S.string(description: '列表标题'),
    'subtitle': S.string(description: '副标题（如更新时间）'),
    'items': ListSchema(
      description: '快讯条目列表',
      items: S.object(
        properties: {
          'text': S.string(description: '快讯内容'),
          'content': S.string(description: '快讯内容（兼容旧格式）'),
          'route': S.string(description: '点击跳转路由'),
          'target': S.string(description: '点击跳转目标（兼容旧格式）'),
        },
      ),
    ),
    'maxItems': S.integer(description: '最多显示条数（可选，默认4条）'),
  },
  required: ['title', 'items'],
);

/// News flash list component.
///
/// A list of short news items with numbered bullets and gradient effects.
final newsFlashList = CatalogItem(
  name: 'newsFlashList',
  dataSchema: _newsFlashListSchema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "newsFlashList": {
              "title": "市场快讯",
              "subtitle": "更新于08:08，更新了3条内容",
              "items": [
                {"text": "国产汽车芯片认证审查技术体系实现突破", "route": "client://ai.route/1"},
                {"text": "狂飙涨停潮！AI应用方向集体走高半导体板块…", "route": "client://ai.route/2"},
                {"text": "沪指低位震荡半日跌0.56%｜AI应用方向全面爆…", "route": "client://ai.route/3"},
                {"text": "瑞银：预计明年中国股市将迎来又一个丰…", "route": "client://ai.route/4"}
              ]
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final String title = data['title'] as String? ?? '';
    final String? subtitle = data['subtitle'] as String?;
    final List<dynamic> items = data['items'] as List<dynamic>? ?? [];
    final int maxItems = data['maxItems'] as int? ?? 4;

    return _NewsFlashList(
      title: title,
      subtitle: subtitle,
      items: items.take(maxItems).map((item) {
        final Map<String, Object?> itemData = item as Map<String, Object?>;
        // Support both 'text' and 'content' keys for backward compatibility
        final String text =
            itemData['text'] as String? ?? itemData['content'] as String? ?? '';
        final String? route =
            itemData['route'] as String? ?? itemData['target'] as String?;
        return _NewsFlashItem(text: text, route: route);
      }).toList(),
      onItemTap: (route) {
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

class _NewsFlashItem {
  const _NewsFlashItem({required this.text, this.route});

  final String text;
  final String? route;
}

class _NewsFlashList extends StatelessWidget {
  const _NewsFlashList({
    required this.title,
    this.subtitle,
    required this.items,
    this.onItemTap,
  });

  final String title;
  final String? subtitle;
  final List<_NewsFlashItem> items;
  final void Function(String? route)? onItemTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                _buildGradientTitle(),
                if (subtitle != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // News items with numbers
          ...items.asMap().entries.map((entry) {
            return _buildNewsItem(entry.key + 1, entry.value);
          }),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildGradientTitle() {
    // Split title to apply gradient to second part
    // e.g., "市场快讯" -> "市场" normal, "快讯" gradient
    if (title.length >= 2) {
      final firstPart = title.substring(0, 2);
      final secondPart = title.substring(2);

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            firstPart,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF6B8EFF), Color(0xFFB06BFF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds),
            child: Text(
              secondPart,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }

    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildNewsItem(int index, _NewsFlashItem item) {
    // Gradient colors for numbers
    final List<Color> numberColors = [
      const Color(0xFF6B8EFF), // Blue
      const Color(0xFF8B6BFF), // Purple
      const Color(0xFFB06BFF), // Violet
      const Color(0xFFFF6B9D), // Pink
    ];

    final Color numberColor = numberColors[(index - 1) % numberColors.length];

    return InkWell(
      onTap: item.route != null ? () => onItemTap?.call(item.route) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Number with gradient bullet
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Gradient circle
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [numberColor, numberColor.withOpacity(0.5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: numberColor.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Content
            Expanded(
              child: Text(
                item.text,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
