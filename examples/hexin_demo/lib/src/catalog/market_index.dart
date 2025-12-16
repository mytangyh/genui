// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Schema for market index component - kept simple.
final _marketIndexSchema = S.object(
  properties: {
    'indexName': S.string(description: '指数名称'),
    'value': S.number(description: '指数值'),
    'change': S.number(description: '涨跌幅(%)'),
  },
  required: ['indexName', 'value'],
);

/// A simple market index display widget.
final marketIndex = CatalogItem(
  name: 'MarketIndex',
  dataSchema: _marketIndexSchema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "MarketIndex": {
              "indexName": "上证指数",
              "value": 3150.28,
              "change": 0.85
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final String indexName = data['indexName'] as String? ?? '';
    final num value = data['value'] as num? ?? 0;
    final num change = data['change'] as num? ?? 0;

    final bool isUp = change >= 0;
    final Color color = isUp ? Colors.red : Colors.green;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            indexName,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            '${isUp ? '+' : ''}${change.toStringAsFixed(2)}%',
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  },
);
