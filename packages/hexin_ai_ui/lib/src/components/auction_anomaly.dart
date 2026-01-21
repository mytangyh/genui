// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Schema for auction anomaly component.
///
/// DSL Example:
/// ```json
/// {
///   "type": "auctionAnomaly",
///   "props": {
///     "timestamp": "1768353900609"
///   }
/// }
/// ```
final _auctionAnomalySchema = S.object(
  description: '集合竞价异动组件，显示集合竞价期间的异常情况',
  properties: {'timestamp': S.string(description: '时间戳')},
);

/// Auction anomaly component (placeholder implementation).
///
/// This is a placeholder for the auctionAnomaly component.
/// The actual implementation should be added later.
final auctionAnomaly = CatalogItem(
  name: 'auctionAnomaly',
  dataSchema: _auctionAnomalySchema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "auctionAnomaly": {
              "timestamp": "1768353900609"
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    return const _AuctionAnomalyPlaceholder();
  },
);

class _AuctionAnomalyPlaceholder extends StatelessWidget {
  const _AuctionAnomalyPlaceholder();

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
          '集合竞价异动组件暂未实现',
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
