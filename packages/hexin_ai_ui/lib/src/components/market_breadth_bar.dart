// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../constants/app_colors.dart';
import '../models/market_breadth_data.dart';
import '../services/market_data_service.dart';

/// Schema for market breadth bar component.
///
/// DSL Example with real-time data:
/// ```json
/// {
///   "type": "marketBreadthBar",
///   "props": {
///     "up": 2272,
///     "down": 1499,
///     "flat": 13,
///     "limitUp": 62,
///     "limitDown": 13,
///     "dataSource": {
///       "type": "polling",
///       "interval": 3000,
///       "url": "https://api.example.com/market/breadth"
///     }
///   }
/// }
/// ```
final _marketBreadthBarSchema = S.object(
  description: '涨跌平统计条，显示市场涨跌情况，支持实时数据',
  properties: {
    'up': S.integer(description: '上涨家数'),
    'down': S.integer(description: '下跌家数'),
    'flat': S.integer(description: '平盘家数'),
    'limitUp': S.integer(description: '涨停家数'),
    'limitDown': S.integer(description: '跌停家数'),
    'dataSource': S.object(
      description: '数据源配置',
      properties: {
        'type': S.string(description: '数据源类型：static | polling | websocket'),
        'interval': S.integer(description: '轮询间隔（毫秒）'),
        'url': S.string(description: '数据源 URL'),
      },
    ),
  },
  required: ['up', 'down'],
);

/// Market breadth bar component with real-time data support.
final marketBreadthBar = CatalogItem(
  name: 'marketBreadthBar',
  dataSchema: _marketBreadthBarSchema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "marketBreadthBar": {
              "up": 2272,
              "down": 1499,
              "flat": 13,
              "limitUp": 62,
              "limitDown": 13
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
            "marketBreadthBar": {
              "up": 2000,
              "down": 1500,
              "flat": 100,
              "limitUp": 50,
              "limitDown": 10,
              "dataSource": {
                "type": "polling",
                "interval": 2000
              }
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;

    // Helper to parse int from either String or num
    int parseIntValue(Object? value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    final int up = parseIntValue(data['up']);
    final int down = parseIntValue(data['down']);
    final int flat = parseIntValue(data['flat']);
    final int limitUp = parseIntValue(data['limitUp']);
    final int limitDown = parseIntValue(data['limitDown']);
    final Map<String, Object?>? dataSource =
        data['dataSource'] as Map<String, Object?>?;

    return MarketBreadthBar(
      initialUp: up,
      initialDown: down,
      initialFlat: flat,
      initialLimitUp: limitUp,
      initialLimitDown: limitDown,
      dataSource: dataSource != null
          ? _DataSourceConfig(
              type: dataSource['type'] as String? ?? 'static',
              interval:
                  parseIntValue(dataSource['interval']).clamp(1000, 60000),
              url: dataSource['url'] as String?,
            )
          : null,
    );
  },
);

class _DataSourceConfig {
  const _DataSourceConfig({required this.type, this.interval = 3000, this.url});

  final String type;
  final int interval;
  final String? url;

  bool get isRealTime => type == 'polling' || type == 'websocket';
}

class MarketBreadthBar extends StatefulWidget {
  const MarketBreadthBar({
    required this.initialUp,
    required this.initialDown,
    this.initialFlat = 0,
    this.initialLimitUp = 0,
    this.initialLimitDown = 0,
    this.dataSource,
  });

  final int initialUp;
  final int initialDown;
  final int initialFlat;
  final int initialLimitUp;
  final int initialLimitDown;
  final _DataSourceConfig? dataSource;

  @override
  State<MarketBreadthBar> createState() => _MarketBreadthBarState();
}

class _MarketBreadthBarState extends State<MarketBreadthBar>
    with SingleTickerProviderStateMixin {
  late MarketBreadthData _data;
  final MarketDataService _service = MarketDataService();
  Timer? _pollingTimer;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _animation;
  MarketBreadthData? _previousData;

  @override
  void initState() {
    super.initState();
    _data = MarketBreadthData(
      up: widget.initialUp,
      down: widget.initialDown,
      flat: widget.initialFlat,
      limitUp: widget.initialLimitUp,
      limitDown: widget.initialLimitDown,
    );

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Start real-time data if configured
    if (widget.dataSource?.isRealTime == true) {
      _startPolling();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startPolling() {
    final interval = widget.dataSource?.interval ?? 3000;
    _pollingTimer = Timer.periodic(
      Duration(milliseconds: interval),
      (_) => _fetchData(),
    );
  }

  Future<void> _fetchData() async {
    // In real implementation, fetch from widget.dataSource.url
    // For now, generate mock data with realistic variations
    final mockData = _generateMockData();

    if (mounted) {
      setState(() {
        _previousData = _data;
        _data = mockData;
        _animationController.forward(from: 0);
      });
    }
  }

  MarketBreadthData _generateMockData() {
    // Use the initial config as base
    final baseData = MarketBreadthData(
      up: widget.initialUp,
      down: widget.initialDown,
      flat: widget.initialFlat,
      limitUp: widget.initialLimitUp,
      limitDown: widget.initialLimitDown,
    );
    return _service.generateMockData(baseData);
  }

  int _interpolate(int from, int to, double t) {
    return (from + (to - from) * t).round();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final displayData = _previousData != null
            ? MarketBreadthData(
                up: _interpolate(_previousData!.up, _data.up, _animation.value),
                down: _interpolate(
                  _previousData!.down,
                  _data.down,
                  _animation.value,
                ),
                flat: _interpolate(
                  _previousData!.flat,
                  _data.flat,
                  _animation.value,
                ),
                limitUp: _interpolate(
                  _previousData!.limitUp,
                  _data.limitUp,
                  _animation.value,
                ),
                limitDown: _interpolate(
                  _previousData!.limitDown,
                  _data.limitDown,
                  _animation.value,
                ),
              )
            : _data;

        return _buildContent(displayData);
      },
    );
  }

  Widget _buildContent(MarketBreadthData data) {
    final total = data.up + data.down + data.flat;
    if (total == 0) return const SizedBox.shrink();

    final upRatio = data.up / total;
    final downRatio = data.down / total;
    final flatRatio = data.flat / total;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Real-time indicator
          if (widget.dataSource?.isRealTime == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.downGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '实时数据',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                // Up section (red)
                Expanded(
                  flex: (upRatio * 1000).toInt().clamp(1, 999),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.gradientRedStart,
                          AppColors.gradientRedEnd
                        ],
                      ),
                    ),
                  ),
                ),
                // Flat section (gray)
                if (flatRatio > 0.001)
                  Expanded(
                    flex: (flatRatio * 1000).toInt().clamp(1, 999),
                    child: Container(color: AppColors.textSecondary),
                  ),
                // Down section (green)
                Expanded(
                  flex: (downRatio * 1000).toInt().clamp(1, 999),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.gradientGreenStart,
                          AppColors.gradientGreenEnd
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Up stats
              _buildStatItem(
                label: '涨',
                value: data.up,
                subValue: data.limitUp > 0 ? '涨停${data.limitUp}' : null,
                color: AppColors.upRed,
              ),
              // Flat stats
              if (data.flat > 0)
                _buildStatItem(
                  label: '平',
                  value: data.flat,
                  color: AppColors.textSecondary,
                ),
              // Down stats
              _buildStatItem(
                label: '跌',
                value: data.down,
                subValue: data.limitDown > 0 ? '跌停${data.limitDown}' : null,
                color: AppColors.downGreen,
                alignRight: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required int value,
    String? subValue,
    required Color color,
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (subValue != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subValue,
              style: TextStyle(color: color.withOpacity(0.7), fontSize: 10),
            ),
          ),
      ],
    );
  }
}
