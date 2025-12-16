// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Schema for trade recommendation component.
final tradeRecommendationSchema = S.object(
  properties: {
    'action': S.string(
      description: '操作类型: buy(买入), sell(卖出), hold(持有)',
      enumValues: ['buy', 'sell', 'hold'],
    ),
    'stockCode': S.string(description: '股票代码'),
    'stockName': S.string(description: '股票名称'),
    'targetPrice': S.number(description: '目标价格'),
    'currentPrice': S.number(description: '当前价格'),
    'confidence': S.number(description: '置信度 (0-100)'),
    'reason': S.string(description: '推荐理由'),
    'timeHorizon': S.string(description: '持有期限'),
  },
  required: ['action', 'stockCode', 'stockName', 'reason'],
);

/// Catalog item for trade recommendation.
final tradeRecommendation = CatalogItem(
  name: 'TradeRecommendation',
  dataSchema: tradeRecommendationSchema,
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final String action = data['action'] as String? ?? 'hold';
    final String stockCode = data['stockCode'] as String? ?? '';
    final String stockName = data['stockName'] as String? ?? '';
    final targetPrice = data['targetPrice'] as num?;
    final currentPrice = data['currentPrice'] as num?;
    final num confidence = data['confidence'] as num? ?? 0;
    final String reason = data['reason'] as String? ?? '';
    final timeHorizon = data['timeHorizon'] as String?;

    Color actionColor;
    IconData actionIcon;
    String actionText;

    switch (action) {
      case 'buy':
        actionColor = Colors.red;
        actionIcon = Icons.trending_up;
        actionText = '买入';
      case 'sell':
        actionColor = Colors.green;
        actionIcon = Icons.trending_down;
        actionText = '卖出';
      default:
        actionColor = Colors.grey;
        actionIcon = Icons.remove;
        actionText = '持有';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with action badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: actionColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(actionIcon, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        actionText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (confidence > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '置信度 ${confidence.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Stock info
            Row(
              children: [
                Text(
                  stockName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  stockCode,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),

            // Price info
            if (currentPrice != null || targetPrice != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (currentPrice != null)
                    _PriceTag(label: '现价', price: currentPrice.toDouble()),
                  if (currentPrice != null && targetPrice != null)
                    const SizedBox(width: 16),
                  if (targetPrice != null)
                    _PriceTag(
                      label: '目标价',
                      price: targetPrice.toDouble(),
                      isTarget: true,
                    ),
                  if (timeHorizon != null) ...[
                    const Spacer(),
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeHorizon,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ],

            // Reason
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reason,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  },
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "TradeRecommendation": {
              "action": "buy",
              "stockCode": "600519",
              "stockName": "贵州茅台",
              "targetPrice": 1800,
              "currentPrice": 1650,
              "confidence": 85,
              "reason": "基本面良好，估值合理，行业龙头地位稳固。近期价格回调提供了较好的买入机会。建议逢低分批建仓。",
              "timeHorizon": "3-6个月"
            }
          }
        }
      ]
    ''',
  ],
);

class _PriceTag extends StatelessWidget {
  const _PriceTag({
    required this.label,
    required this.price,
    this.isTarget = false,
  });

  final String label;
  final double price;
  final bool isTarget;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          '¥${price.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isTarget ? Colors.orange : Colors.black,
          ),
        ),
      ],
    );
  }
}
