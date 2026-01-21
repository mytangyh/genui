// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Schema for stock quote component - kept simple to avoid schema limits.
final _stockQuoteSchema = S.object(
  properties: {
    'stockName': S.string(description: '股票名称'),
    'stockCode': S.string(description: '股票代码'),
    'price': S.number(description: '当前价格'),
    'change': S.number(description: '涨跌幅(%)'),
  },
  required: ['stockName', 'stockCode', 'price'],
);

/// A simple stock quote display card.
final stockQuote = CatalogItem(
  name: 'StockQuote',
  dataSchema: _stockQuoteSchema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "StockQuote": {
              "stockName": "贵州茅台",
              "stockCode": "600519",
              "price": 1688.50,
              "change": 2.35
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final String stockName = data['stockName'] as String? ?? '';
    final String stockCode = data['stockCode'] as String? ?? '';
    final num price = data['price'] as num? ?? 0;
    final num change = data['change'] as num? ?? 0;

    final bool isUp = change >= 0;
    final Color color = isUp ? Colors.red : Colors.green;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stockName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stockCode,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '¥${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  '${isUp ? '+' : ''}${change.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  },
);
