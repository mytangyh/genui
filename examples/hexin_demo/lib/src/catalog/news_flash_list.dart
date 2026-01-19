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
///     "subtitle": "更新于08:08, 更新了3条内容",
///     "items": [
///       {
///         "content": "国产汽车芯片认证审查技术体系实现突破",
///         "tag": "热",
///         "tagColor": "#FF4444"
///       },
///       {
///         "content": "红旗涨停潮！AI应用方向集体走高半导体板块...",
///         "tag": "新",
///         "tagColor": "#FF8800"
///       }
///     ]
///   }
/// }
/// ```
final _newsFlashListSchema = S.object(
  description: '快讯列表组件，显示多条简短新闻快讯，支持标签标记',
  properties: {
    'title': S.string(description: '列表标题'),
    'subtitle': S.string(description: '副标题（如更新时间）'),
    'items': ListSchema(
      description: '快讯条目列表',
      items: S.object(
        properties: {
          'content': S.string(description: '快讯内容'),
          'tag': S.string(description: '标签文字（如"热"、"新"）'),
          'tagColor': S.string(description: '标签颜色，十六进制如 #FF4444'),
          'target': S.string(description: '点击跳转目标 URL'),
        },
        required: ['content'],
      ),
    ),
    'maxItems': S.integer(description: '最多显示条数（可选，默认4条）'),
  },
  required: ['title', 'items'],
);

/// News flash list component.
///
/// A list of short news items with optional tags.
/// Based on the design showing "市场快讯" with bullet points and hot/new tags.
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
              "subtitle": "更新于08:08, 更新了3条内容",
              "items": [
                {
                  "content": "国产汽车芯片认证审查技术体系实现突破",
                  "tag": "热",
                  "tagColor": "#FF4444"
                },
                {
                  "content": "红旗涨停潮！AI应用方向集体走高半导体板块...",
                  "tag": "新",
                  "tagColor": "#FF8800"
                },
                {
                  "content": "沪指低位震荡半日跌0.56%AI应用方向全面爆发",
                  "tag": "",
                  "tagColor": ""
                },
                {
                  "content": "瑞银：预计明年中国股市将迎来又一丰...",
                  "tag": "",
                  "tagColor": ""
                }
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
        return _NewsFlashItem(
          content: itemData['content'] as String? ?? '',
          tag: itemData['tag'] as String?,
          tagColor: itemData['tagColor'] as String?,
          target: itemData['target'] as String?,
        );
      }).toList(),
      onItemTap: (target) {
        if (target != null) {
          context.dispatchEvent(
            UserActionEvent(
              name: 'navigate',
              sourceComponentId: context.id,
              context: {'target': target},
            ),
          );
        }
      },
    );
  },
);

class _NewsFlashItem {
  const _NewsFlashItem({
    required this.content,
    this.tag,
    this.tagColor,
    this.target,
  });

  final String content;
  final String? tag;
  final String? tagColor;
  final String? target;
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
  final void Function(String? target)? onItemTap;

  Color _parseTagColor(String? hex) {
    if (hex == null || hex.isEmpty) {
      return Colors.grey;
    }
    final hexValue = hex.replaceFirst('#', '');
    try {
      return Color(int.parse('FF$hexValue', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // News items
          ...items.asMap().entries.map((entry) {
            final item = entry.value;
            return _buildNewsItem(item);
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildNewsItem(_NewsFlashItem item) {
    return InkWell(
      onTap: item.target != null ? () => onItemTap?.call(item.target) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bullet point
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: item.tag != null && item.tag!.isNotEmpty
                    ? _parseTagColor(item.tagColor)
                    : Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            // Tag
            if (item.tag != null && item.tag!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _parseTagColor(item.tagColor).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.tag!,
                  style: TextStyle(
                    color: _parseTagColor(item.tagColor),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            // Content
            Expanded(
              child: Text(
                item.content,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 14,
                  height: 1.4,
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
