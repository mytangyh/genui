// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Schema for intraday anomaly component.
///
/// DSL Example:
/// ```json
/// {
///   "type": "intradayAnomaly",
///   "props": {
///     "timestamp": "1768353900609"
///   }
/// }
/// ```
final _intradayAnomalySchema = S.object(
  description: '盘中异动组件，显示盘中交易期间的异常情况',
  properties: {'timestamp': S.string(description: '时间戳')},
);

/// Intraday anomaly component (placeholder implementation).
///
/// This is a placeholder for the intradayAnomaly component.
/// The actual implementation should be added later.
final intradayAnomaly = CatalogItem(
  name: 'intradayAnomaly',
  dataSchema: _intradayAnomalySchema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "intradayAnomaly": {
              "timestamp": "1768353900609"
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    return const _IntradayAnomalyPlaceholder();
  },
);

class _IntradayAnomalyPlaceholder extends StatelessWidget {
  const _IntradayAnomalyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A3A4D), width: 1),
      ),
      child: Center(
        child: Text(
          '盘中异动组件暂未实现',
          style: TextStyle(
            fontFamily: 'PingFangSC',
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}
