// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../constants/app_colors.dart';

/// Schema for native chart card component.
///
/// DSL Example:
/// ```json
/// {
///   "type": "nativeChartCard",
///   "props": {
///     "stockCode": "600000",
///     "height": 200,
///     "refreshInterval": 1000
///   }
/// }
/// ```
final _nativeChartCardSchema = S.object(
  description: '原生图表卡片，嵌入 Android 原生视图实现实时数据展示',
  properties: {
    'stockCode': S.string(description: '股票代码'),
    'height': S.number(description: '卡片高度'),
    'refreshInterval': S.integer(description: '数据刷新间隔（毫秒）'),
  },
);

/// Native chart card component using Android PlatformView.
final nativeChartCard = CatalogItem(
  name: 'nativeChartCard',
  dataSchema: _nativeChartCardSchema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "nativeChartCard": {
              "stockCode": "600000",
              "height": 200,
              "refreshInterval": 1000
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final stockCode = data['stockCode'] as String? ?? '000001';
    final height = (data['height'] as num?)?.toDouble() ?? 200;
    final refreshInterval = (data['refreshInterval'] as num?)?.toInt() ?? 1000;

    return NativeChartCardWidget(
      key: ValueKey('native-chart-$stockCode'),
      stockCode: stockCode,
      height: height,
      refreshInterval: refreshInterval,
    );
  },
);

/// Widget that embeds a native Android chart view with visibility-based
/// lifecycle management.
class NativeChartCardWidget extends StatefulWidget {
  const NativeChartCardWidget({
    super.key,
    required this.stockCode,
    this.height = 200,
    this.refreshInterval = 1000,
  });

  final String stockCode;
  final double height;
  final int refreshInterval;

  @override
  State<NativeChartCardWidget> createState() => _NativeChartCardWidgetState();
}

class _NativeChartCardWidgetState extends State<NativeChartCardWidget>
    with WidgetsBindingObserver {
  MethodChannel? _channel;
  bool _isAppActive = true;
  int? _viewId;

  @override
  void initState() {
    super.initState();
    debugPrint('[NativeChartCard] initState - stock: ${widget.stockCode}');
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    debugPrint('[NativeChartCard] dispose - viewId: $_viewId');
    WidgetsBinding.instance.removeObserver(this);
    _stopUpdates();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[NativeChartCard] App lifecycle: $state');
    final wasActive = _isAppActive;
    _isAppActive = state == AppLifecycleState.resumed;

    if (wasActive != _isAppActive) {
      _updateRunningState();
    }
  }

  void _onPlatformViewCreated(int id) {
    _viewId = id;
    debugPrint('[NativeChartCard] PlatformView created - viewId: $id');
    _channel = MethodChannel('native-chart-view-$id');

    // Robust startup: send START multiple times with delays
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: 100 + i * 500), () {
        if (mounted && _isAppActive) {
          debugPrint(
              '[NativeChartCard] Auto-start attempt ${i + 1} for viewId: $_viewId');
          _startUpdates();
        }
      });
    }
  }

  void _updateRunningState() {
    if (_channel == null) {
      debugPrint('[NativeChartCard] updateRunningState: channel is null');
      return;
    }

    final shouldRun = _isAppActive;
    debugPrint(
      '[NativeChartCard] updateRunningState: shouldRun=$shouldRun '
      '(active=$_isAppActive)',
    );

    if (shouldRun) {
      _startUpdates();
    } else {
      _stopUpdates();
    }
  }

  void _startUpdates() {
    debugPrint('[NativeChartCard] >>> Sending START to viewId=$_viewId');
    _safeInvoke('start');
  }

  void _stopUpdates() {
    debugPrint('[NativeChartCard] >>> Sending STOP to viewId=$_viewId');
    _safeInvoke('stop');
  }

  Future<void> _safeInvoke(String method) async {
    try {
      await _channel?.invokeMethod(method);
    } on MissingPluginException catch (e) {
      debugPrint('[NativeChartCard] Channel disposed, ignoring $method: $e');
    } catch (e) {
      debugPrint('[NativeChartCard] Error invoking $method: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only render AndroidView on Android platform
    if (!Platform.isAndroid) {
      return _buildFallback();
    }

    return Container(
      height: widget.height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: AndroidView(
        viewType: 'native-chart-view',
        creationParams: {
          'stockCode': widget.stockCode,
          'refreshInterval': widget.refreshInterval,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      height: widget.height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          'Native Chart (Android Only)\nStock: ${widget.stockCode}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54),
        ),
      ),
    );
  }
}
