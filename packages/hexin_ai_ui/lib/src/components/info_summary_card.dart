// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Schema for info summary card component.
///
/// DSL Example:
/// ```json
/// {
///   "type": "infoSummaryCard",
///   "props": {
///     "title": "早间必读",
///     "summary": "美国国会众议院以222票对209票通过临时拨款法案。",
///     "action": {
///       "text": "查看详情",
///       "target": "aiapp://news/detail?id=123"
///     }
///   }
/// }
/// ```
final _infoSummaryCardSchema = S.object(
  description: '信息摘要卡片，用于展示新闻、资讯等简要信息，支持点击查看详情',
  properties: {
    'title': S.string(description: '卡片标题'),
    'summary': S.string(description: '摘要内容'),
    'action': S.object(
      description: '点击操作配置',
      properties: {
        'text': S.string(description: '操作按钮文字'),
        'target': S.string(description: '跳转目标 URL 或 scheme'),
      },
    ),
    'backgroundColor': S.string(description: '背景颜色（可选，十六进制如 #1E2A3D）'),
  },
  required: ['title', 'summary'],
);

/// Info summary card component.
///
/// A card displaying title, summary text, and an optional action button.
/// Based on the design showing "早间必读" cards with summary and action.
final infoSummaryCard = CatalogItem(
  name: 'infoSummaryCard',
  dataSchema: _infoSummaryCardSchema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "infoSummaryCard": {
              "title": "早间必读",
              "summary": "美国国会众议院以222票支持209票反对通过参议院已通过的联邦政府临时拨款法案。",
              "action": {
                "text": "查看详情",
                "target": "aiapp://news/detail?id=123"
              }
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
            "infoSummaryCard": {
              "title": "盘前必读",
              "summary": "对盘前解读的资讯内容进行AI汇总解读，并完整展示在这里。点击查看详情跳转到资讯二级页。",
              "action": {
                "text": "查看详情",
                "target": "aiapp://news/premarket"
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
    final String summary = data['summary'] as String? ?? '';
    // Support optional contentTitle field from API
    final String? contentTitle = data['contentTitle'] as String?;
    final Map<String, Object?>? action =
        data['action'] as Map<String, Object?>?;
    final String? backgroundColor = data['backgroundColor'] as String?;

    // Support both 'route' (API format) and 'target' (schema format)
    final String? actionTarget =
        action?['route'] as String? ?? action?['target'] as String?;

    return _InfoSummaryCard(
      title: title,
      summary: summary,
      contentTitle: contentTitle,
      actionText: action?['text'] as String?,
      actionTarget: actionTarget,
      backgroundColor: backgroundColor,
      onAction: () {
        if (actionTarget != null) {
          context.dispatchEvent(
            UserActionEvent(
              name: 'navigate',
              sourceComponentId: context.id,
              context: {'target': actionTarget},
            ),
          );
        }
      },
    );
  },
);

class _InfoSummaryCard extends StatelessWidget {
  const _InfoSummaryCard({
    required this.title,
    required this.summary,
    this.contentTitle,
    this.actionText,
    this.actionTarget,
    this.backgroundColor,
    this.onAction,
  });

  final String title;
  final String summary;
  final String? contentTitle;
  final String? actionText;
  final String? actionTarget;
  final String? backgroundColor;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF25487C), Color(0xFF232232)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.7], // Smooth transition
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and action
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'PingFangSC',
                    fontWeight: FontWeight.w400,
                    fontSize: 18,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
                if (actionText != null || actionTarget != null)
                  GestureDetector(
                    onTap: onAction,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          actionText ?? '查看详情',
                          style: const TextStyle(
                            fontFamily: 'PingFangSC',
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: Color(0xFFA7A7A7),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Color(0xFFA7A7A7),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Content title (if available)
          if (contentTitle != null && contentTitle!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                contentTitle!,
                style: const TextStyle(
                  fontFamily: 'PingFangSC',
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ),
          // Summary text
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              summary,
              style: const TextStyle(
                fontFamily: 'PingFangSC',
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Color(0xFFD2D2D3),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
