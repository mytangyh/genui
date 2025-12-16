// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Schema for risk assessment card component.
final riskAssessmentSchema = S.object(
  properties: {
    'riskLevel': S.string(
      description: '风险等级: low(低风险), medium(中风险), high(高风险)',
      enumValues: ['low', 'medium', 'high'],
    ),
    'riskScore': S.number(description: '风险评分 (0-100)'),
    'volatility': S.number(description: '波动率 (小数形式，如 0.15 表示 15%)'),
    'diversification': S.number(description: '分散度评分 (0-100)'),
    'suggestions': S.list(items: S.string(), description: '风险优化建议列表'),
  },
  required: ['riskLevel', 'riskScore'],
);

/// Catalog item for risk assessment card.
final riskAssessmentCard = CatalogItem(
  name: 'RiskAssessmentCard',
  dataSchema: riskAssessmentSchema,
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final String riskLevel = data['riskLevel'] as String? ?? 'medium';
    final num riskScore = data['riskScore'] as num? ?? 50;
    final num volatility = data['volatility'] as num? ?? 0;
    final num diversification = data['diversification'] as num? ?? 0;
    final List<dynamic> suggestions = data['suggestions'] as List? ?? [];

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Row(
              children: [
                Icon(Icons.shield, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  '风险评估',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Risk score gauge
            _RiskGauge(riskLevel: riskLevel, riskScore: riskScore.toDouble()),
            const SizedBox(height: 20),

            // Metrics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MetricItem(
                  label: '波动率',
                  value: '${(volatility.toDouble() * 100).toStringAsFixed(1)}%',
                ),
                _MetricItem(
                  label: '分散度',
                  value: '${diversification.toStringAsFixed(0)}分',
                ),
              ],
            ),

            // Suggestions
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                '优化建议',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...suggestions.map((suggestion) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        size: 18,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          suggestion.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
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
            "RiskAssessmentCard": {
              "riskLevel": "medium",
              "riskScore": 65,
              "volatility": 0.15,
              "diversification": 70,
              "suggestions": [
                "建议增加债券配置以降低波动性",
                "建议分散到不同行业以提高多样性",
                "考虑添加一些防御性股票"
              ]
            }
          }
        }
      ]
    ''',
  ],
);

class _RiskGauge extends StatelessWidget {
  const _RiskGauge({required this.riskLevel, required this.riskScore});

  final String riskLevel;
  final double riskScore;

  @override
  Widget build(BuildContext context) {
    Color riskColor;
    String riskText;

    switch (riskLevel) {
      case 'low':
        riskColor = Colors.green;
        riskText = '低风险';
      case 'high':
        riskColor = Colors.red;
        riskText = '高风险';
      default:
        riskColor = Colors.orange;
        riskText = '中风险';
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 120,
              width: 120,
              child: CircularProgressIndicator(
                value: riskScore / 100,
                strokeWidth: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(riskColor),
              ),
            ),
            Column(
              children: [
                Text(
                  riskScore.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: riskColor,
                  ),
                ),
                Text(
                  riskText,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
