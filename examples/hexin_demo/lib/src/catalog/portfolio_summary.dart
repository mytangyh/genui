// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:intl/intl.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Schema for portfolio summary component.
final portfolioSummarySchema = S.object(
  properties: {
    'totalValue': S.number(description: '总资产（元）'),
    'totalProfit': S.number(description: '总盈亏（元）'),
    'profitPercent': S.number(description: '收益率（%）'),
    'holdingsJson': S.string(description: 'JSON格式的持仓数据'),
  },
  required: ['totalValue'],
);

/// Catalog item for portfolio summary.
final portfolioSummary = CatalogItem(
  name: 'PortfolioSummary',
  dataSchema: portfolioSummarySchema,
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '投资组合概览',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Summary stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: _PortfolioStats(data: data),
          ),

          // Divider
          const Divider(height: 1),

          // Holdings list
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '持仓明细',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _HoldingsList(data: data),
              ],
            ),
          ),
        ],
      ),
    );
  },
);

class _PortfolioStats extends StatelessWidget {
  const _PortfolioStats({required this.data});

  final Map<String, Object?> data;

  @override
  Widget build(BuildContext context) {
    final num totalValue = data['totalValue'] as num? ?? 0;
    final num totalProfit = data['totalProfit'] as num? ?? 0;
    final num profitPercent = data['profitPercent'] as num? ?? 0;

    final formatter = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');
    final bool isProfit = totalProfit >= 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatItem(
          label: '总资产',
          value: formatter.format(totalValue),
          color: Colors.black,
        ),
        _StatItem(
          label: '总盈亏',
          value: formatter.format(totalProfit.abs()),
          color: isProfit ? Colors.red : Colors.green,
          prefix: isProfit ? '+' : '-',
        ),
        _StatItem(
          label: '收益率',
          value: '${profitPercent.abs().toStringAsFixed(2)}%',
          color: isProfit ? Colors.red : Colors.green,
          prefix: isProfit ? '+' : '-',
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    this.prefix,
  });

  final String label;
  final String value;
  final Color color;
  final String? prefix;

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
          '${prefix ?? ''}$value',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _HoldingsList extends StatelessWidget {
  const _HoldingsList({required this.data});

  final Map<String, Object?> data;

  @override
  Widget build(BuildContext context) {
    final List<dynamic> holdings = data['holdings'] as List? ?? [];

    if (holdings.isEmpty) {
      return const Text('暂无持仓');
    }

    return Column(
      children: holdings.map((holding) {
        final Map<String, Object?> holdingData =
            holding as Map<String, Object?>? ?? {};
        return _HoldingItem(data: holdingData);
      }).toList(),
    );
  }
}

class _HoldingItem extends StatelessWidget {
  const _HoldingItem({required this.data});

  final Map<String, Object?> data;

  @override
  Widget build(BuildContext context) {
    final String stockCode = data['stockCode'] as String? ?? '';
    final String stockName = data['stockName'] as String? ?? '';
    final num shares = data['shares'] as num? ?? 0;
    final num costPrice = data['costPrice'] as num? ?? 0;
    final num currentPrice = data['currentPrice'] as num? ?? 0;
    final num profit = data['profit'] as num? ?? 0;
    final num profitPercent = data['profitPercent'] as num? ?? 0;

    final bool isProfit = profit >= 0;
    final MaterialColor profitColor = isProfit ? Colors.red : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      stockName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      stockCode,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '持仓: $shares股 | 成本: ¥${costPrice.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '¥${currentPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${isProfit ? '+' : ''}${profitPercent.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: profitColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
