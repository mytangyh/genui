// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

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
    final int up = (data['up'] as num?)?.toInt() ?? 0;
    final int down = (data['down'] as num?)?.toInt() ?? 0;
    final int flat = (data['flat'] as num?)?.toInt() ?? 0;
    final int limitUp = (data['limitUp'] as num?)?.toInt() ?? 0;
    final int limitDown = (data['limitDown'] as num?)?.toInt() ?? 0;
    final Map<String, Object?>? dataSource =
        data['dataSource'] as Map<String, Object?>?;

    return _MarketBreadthBar(
      initialUp: up,
      initialDown: down,
      initialFlat: flat,
      initialLimitUp: limitUp,
      initialLimitDown: limitDown,
      dataSource: dataSource != null
          ? _DataSourceConfig(
              type: dataSource['type'] as String? ?? 'static',
              interval: (dataSource['interval'] as num?)?.toInt() ?? 3000,
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

class _MarketBreadthData {
  const _MarketBreadthData({
    required this.up,
    required this.down,
    this.flat = 0,
    this.limitUp = 0,
    this.limitDown = 0,
  });

  final int up;
  final int down;
  final int flat;
  final int limitUp;
  final int limitDown;
}

class _MarketBreadthBar extends StatefulWidget {
  const _MarketBreadthBar({
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
  State<_MarketBreadthBar> createState() => _MarketBreadthBarState();
}

class _MarketBreadthBarState extends State<_MarketBreadthBar>
    with SingleTickerProviderStateMixin {
  late _MarketBreadthData _data;
  Timer? _pollingTimer;
  final Random _random = Random();

  // Animation
  late AnimationController _animationController;
  late Animation<double> _animation;
  _MarketBreadthData? _previousData;

  @override
  void initState() {
    super.initState();
    _data = _MarketBreadthData(
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

  _MarketBreadthData _generateMockData() {
    // Generate realistic market data variations
    final baseUp = widget.initialUp;
    final baseDown = widget.initialDown;

    // Random fluctuations within ±10%
    final upChange = (baseUp * 0.1 * (_random.nextDouble() - 0.5)).toInt();
    final downChange = (baseDown * 0.1 * (_random.nextDouble() - 0.5)).toInt();
    final flatChange = (_random.nextInt(20) - 10);

    final newUp = (baseUp + upChange).clamp(100, 5000);
    final newDown = (baseDown + downChange).clamp(100, 5000);
    final newFlat = (widget.initialFlat + flatChange).clamp(0, 500);

    // Limit up/down also fluctuate
    final limitUpChange = _random.nextInt(10) - 5;
    final limitDownChange = _random.nextInt(6) - 3;

    return _MarketBreadthData(
      up: newUp,
      down: newDown,
      flat: newFlat,
      limitUp: (widget.initialLimitUp + limitUpChange).clamp(0, 200),
      limitDown: (widget.initialLimitDown + limitDownChange).clamp(0, 100),
    );
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
            ? _MarketBreadthData(
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

  Widget _buildContent(_MarketBreadthData data) {
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
                      color: Colors.green,
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
                        colors: [Color(0xFFFF4444), Color(0xFFFF6B6B)],
                      ),
                    ),
                  ),
                ),
                // Flat section (gray)
                if (flatRatio > 0.001)
                  Expanded(
                    flex: (flatRatio * 1000).toInt().clamp(1, 999),
                    child: Container(color: const Color(0xFF666666)),
                  ),
                // Down section (green)
                Expanded(
                  flex: (downRatio * 1000).toInt().clamp(1, 999),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF00C853), Color(0xFF4CAF50)],
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
                color: const Color(0xFFFF4444),
              ),
              // Flat stats
              if (data.flat > 0)
                _buildStatItem(
                  label: '平',
                  value: data.flat,
                  color: const Color(0xFF888888),
                ),
              // Down stats
              _buildStatItem(
                label: '跌',
                value: data.down,
                subValue: data.limitDown > 0 ? '跌停${data.limitDown}' : null,
                color: const Color(0xFF00C853),
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
