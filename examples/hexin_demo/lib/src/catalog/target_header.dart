import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:intl/intl.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Schema for target header component.
///
/// DSL Example:
/// ```json
/// {
///   "type": "targetHeader",
///   "props": {
///     "timestamp": "1768353940688",
///     "title": "盘前",
///     "targetName": "上证指数",
///     "targetValue": "4138.65  -0.00%",
///     "trend": "flat"
///   }
/// }
/// ```
final _targetHeaderSchema = S.object(
  description: '标的头部组件，显示时间、阶段、标的名称和数值',
  properties: {
    'timestamp': S.string(description: '时间戳（毫秒），如 1768353940688'),
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
              "timestamp": "1768353940688",
              "title": "盘前",
              "targetName": "上证指数",
              "targetValue": "4138.65  -0.00%",
              "trend": "flat"
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
              "timestamp": "1768440320905",
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

  /// Format timestamp based on date context
  /// - Today: "HH:mm"
  /// - Yesterday: "昨天 HH:mm"
  /// - This year: "MM-dd HH:mm"
  /// - Previous years: "yyyy-MM-dd HH:mm"
  String _formatTimestamp(String timestampStr) {
    try {
      final timestamp = int.parse(timestampStr);
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final dateOnly = DateTime(date.year, date.month, date.day);

      if (dateOnly == today) {
        // Today: show only time
        return DateFormat('HH:mm').format(date);
      } else if (dateOnly == yesterday) {
        // Yesterday: show "昨天 HH:mm"
        return '昨天 ${DateFormat('HH:mm').format(date)}';
      } else if (date.year == now.year) {
        // This year: show "MM-dd HH:mm"
        return DateFormat('MM-dd HH:mm').format(date);
      } else {
        // Previous years: show "yyyy-MM-dd HH:mm"
        return DateFormat('yyyy-MM-dd HH:mm').format(date);
      }
    } catch (e) {
      return timestampStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side: timestamp | title (左对齐)
          if (timestamp != null || title != null)
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildLeftSection(),
              ),
            ),
          // Right side: targetName + targetValue (右对齐)
          Align(alignment: Alignment.centerRight, child: _buildRightSection()),
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
            _formatTimestamp(timestamp!),
            style: const TextStyle(
              fontFamily: 'PingFangSC',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: Color(0xFFA9A9A9),
              height: 1.5, // 18sp line-height / 12sp font-size = 1.5
            ),
          ),
        if (timestamp != null && title != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '|',
              style: const TextStyle(
                fontFamily: 'PingFangSC',
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: Color(0xFFA9A9A9),
                height: 1.5,
              ),
            ),
          ),
        if (title != null)
          Text(
            title!,
            style: const TextStyle(
              fontFamily: 'PingFangSC',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: Color(0xFFA9A9A9),
              height: 1.5,
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
            fontFamily: 'PingFangSC',
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Color(0xFFFFFFFF),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          targetValue,
          style: TextStyle(
            fontFamily: 'PingFangSC',
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: _getTrendColor(),
          ),
        ),
      ],
    );
  }
}
