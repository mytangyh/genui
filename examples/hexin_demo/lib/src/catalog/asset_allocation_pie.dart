// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Schema for asset allocation pie chart component.
final assetAllocationSchema = S.object(
  properties: {
    'allocationsJson': S.string(description: 'JSON格式的资产配置数据'),
    'title': S.string(description: '图表标题'),
  },
  required: ['allocationsJson'],
);

/// Catalog item for asset allocation pie chart.
final assetAllocationPie = CatalogItem(
  name: 'AssetAllocationPie',
  dataSchema: assetAllocationSchema,
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final List<dynamic> allocations = data['allocations'] as List? ?? [];
    final String title = data['title'] as String? ?? '资产配置';

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (allocations.isNotEmpty)
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _PieChart(allocations: allocations),
                    ),
                    const SizedBox(width: 20),
                    Expanded(child: _Legend(allocations: allocations)),
                  ],
                ),
              )
            else
              const SizedBox(height: 200, child: Center(child: Text('暂无数据'))),
          ],
        ),
      ),
    );
  },
);

class _PieChart extends StatelessWidget {
  const _PieChart({required this.allocations});

  final List allocations;

  @override
  Widget build(BuildContext context) {
    final sections = <PieChartSectionData>[];
    final List<MaterialColor> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    for (var i = 0; i < allocations.length; i++) {
      final allocation = allocations[i] as Map<String, Object?>?;
      if (allocation == null) continue;

      final num percentage = allocation['percentage'] as num? ?? 0;

      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: percentage.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return PieChart(
      PieChartData(sections: sections, sectionsSpace: 2, centerSpaceRadius: 40),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.allocations});

  final List allocations;

  @override
  Widget build(BuildContext context) {
    final List<MaterialColor> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: allocations.asMap().entries.map((entry) {
        final int i = entry.key;
        final Map<String, Object?> allocation =
            entry.value as Map<String, Object?>? ?? {};
        final String category = allocation['category'] as String? ?? '';
        final num percentage = allocation['percentage'] as num? ?? 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors[i % colors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '$category ${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
