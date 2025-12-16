// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Schema for stock chart component.
final stockChartSchema = S.object(
  properties: {
    'stockCode': S.string(description: '股票代码'),
    'stockName': S.string(description: '股票名称'),
    'currentPrice': S.number(description: '当前价格'),
    'changePercent': S.number(description: '涨跌幅百分比'),
    'priceHistory': S.list(
      items: S.object(properties: {'price': S.number()}),
      description: '价格历史数据',
    ),
  },
  required: ['stockCode', 'stockName', 'currentPrice'],
);

/// Catalog item for stock chart.
final stockChart = CatalogItem(
  name: 'StockChart',
  dataSchema: stockChartSchema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "StockChart": {
              "stockCode": "600519",
              "stockName": "贵州茅台",
              "currentPrice": 1688.50,
              "changePercent": 2.35,
              "priceHistory": [
                {"price": 1650.00},
                {"price": 1665.80},
                {"price": 1672.30},
                {"price": 1680.00},
                {"price": 1688.50}
              ]
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final String stockCode = data['stockCode'] as String? ?? '';
    final String stockName = data['stockName'] as String? ?? '';
    final num currentPrice = data['currentPrice'] as num? ?? 0;
    final num changePercent = data['changePercent'] as num? ?? 0;
    final List<dynamic> priceHistory = data['priceHistory'] as List? ?? [];

    final bool isRising = changePercent >= 0;
    final MaterialColor trendColor = isRising ? Colors.red : Colors.green;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stockName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stockCode,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '¥${currentPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: trendColor,
                      ),
                    ),
                    Text(
                      '${isRising ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: trendColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Chart
            if (priceHistory.isNotEmpty)
              SizedBox(
                height: 200,
                child: _PriceChart(priceHistory: priceHistory),
              )
            else
              const SizedBox(height: 200, child: Center(child: Text('暂无图表数据'))),
          ],
        ),
      ),
    );
  },
);

class _PriceChart extends StatelessWidget {
  const _PriceChart({required this.priceHistory});

  final List<dynamic> priceHistory;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    double minPrice = double.infinity;
    double maxPrice = double.negativeInfinity;

    for (var i = 0; i < priceHistory.length; i++) {
      final point = priceHistory[i] as Map<String, Object?>?;
      if (point == null) continue;

      final num price = point['price'] as num? ?? 0;
      final double priceDouble = price.toDouble();

      spots.add(FlSpot(i.toDouble(), priceDouble));
      minPrice = minPrice < priceDouble ? minPrice : priceDouble;
      maxPrice = maxPrice > priceDouble ? maxPrice : priceDouble;
    }

    if (spots.isEmpty) {
      return const Center(child: Text('无数据'));
    }

    // Ensure valid interval for grid
    double interval = (maxPrice - minPrice) / 4;
    if (interval <= 0) interval = 1.0;

    final bool isRising = spots.last.y >= spots.first.y;
    final MaterialColor lineColor = isRising ? Colors.red : Colors.green;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          bottomTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                );
              },
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: spots.length.toDouble() - 1,
        minY: minPrice * 0.995,
        maxY: maxPrice * 1.005,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: lineColor.withAlpha((0.1 * 255).round()),
            ),
          ),
        ],
      ),
    );
  }
}
