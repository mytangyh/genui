// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Schema for target header component.
///
/// DSL Example:
/// ```json
/// {
///   "type": "targetHeader",
///   "props": {
///     "timestamp": "08:16",
///     "title": "盘前",
///     "targetName": "上证指数",
///     "targetValue": "3990.49",
///     "trend": "up"
///   }
/// }
/// ```
final _targetHeaderSchema = S.object(
  description: '标的头部组件，显示时间、阶段、标的名称和数值',
  properties: {
    'timestamp': S.string(description: '时间戳，如 08:16'),
    'title': S.string(description: '标签或阶段文案，如：盘前 / 盘中 / 昨收'),
    'targetName': S.string(description: '标的名称，如：上证指数'),
    'targetValue': S.string(description: '数值，如：3990.49 (+0.32%)'),
    'trend': S.string(description: '趋势：up / down / flat'),
  },
  required: ['targetName', 'targetValue'],
);

/// Target header component.
///
/// Displays a header with timestamp, title, target name, and value.
/// Based on the design showing "08:16 | 盘前    上证指数 3990.49".
final targetHeader = CatalogItem(
  name: 'targetHeader',
  dataSchema: _targetHeaderSchema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "targetHeader": {
              "timestamp": "08:16",
              "title": "盘前",
              "targetName": "上证指数",
              "targetValue": "3990.49",
              "trend": "up"
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
            "targetHeader": {
              "timestamp": "15:00",
              "title": "昨收",
              "targetName": "深证成指",
              "targetValue": "11892.35 (-0.56%)",
              "trend": "down"
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final String? timestamp = data['timestamp'] as String?;
    final String? title = data['title'] as String?;
    final String targetName = data['targetName'] as String? ?? '';
    final String targetValue = data['targetValue'] as String? ?? '';
    final String trend = data['trend'] as String? ?? 'flat';

    return _TargetHeader(
      timestamp: timestamp,
      title: title,
      targetName: targetName,
      targetValue: targetValue,
      trend: trend,
    );
  },
);

class _TargetHeader extends StatelessWidget {
  const _TargetHeader({
    this.timestamp,
    this.title,
    required this.targetName,
    required this.targetValue,
    this.trend = 'flat',
  });

  final String? timestamp;
  final String? title;
  final String targetName;
  final String targetValue;
  final String trend;

  Color _getTrendColor() {
    switch (trend.toLowerCase()) {
      case 'up':
        return const Color(0xFFFF4444);
      case 'down':
        return const Color(0xFF00C853);
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1421),
        border: Border(bottom: BorderSide(color: Color(0xFF1E2A3D), width: 1)),
      ),
      child: Row(
        children: [
          // Left side: timestamp | title
          if (timestamp != null || title != null) ...[
            _buildLeftSection(),
            const SizedBox(width: 16),
          ],
          // Spacer to push right content
          const Spacer(),
          // Right side: targetName + targetValue
          _buildRightSection(),
        ],
      ),
    );
  }

  Widget _buildLeftSection() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (timestamp != null)
          Text(
            timestamp!,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        if (timestamp != null && title != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '|',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
              ),
            ),
          ),
        if (title != null)
          Text(
            title!,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
      ],
    );
  }

  Widget _buildRightSection() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          targetName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          targetValue,
          style: TextStyle(
            color: _getTrendColor(),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
