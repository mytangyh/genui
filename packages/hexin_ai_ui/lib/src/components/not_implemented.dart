// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Schema for not implemented component.
///
/// DSL Example:
/// ```json
/// {
///   "type": "notImplemented",
///   "props": {
///     "typeName": "someComponent"
///   }
/// }
/// ```
final _notImplementedSchema = S.object(
  description: '通用暂未实现组件，用于显示未实现的组件类型名称',
  properties: {
    'typeName': S.string(description: '未实现的组件类型名称'),
  },
);

/// Generic not implemented component.
///
/// This component displays a placeholder UI indicating that a specific
/// component type is not yet implemented, showing the type name.
final notImplemented = CatalogItem(
  name: 'notImplemented',
  dataSchema: _notImplementedSchema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "notImplemented": {
              "typeName": "someComponent"
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final typeName = data['typeName'] as String? ?? 'unknown';
    return _NotImplementedWidget(typeName: typeName);
  },
);

class _NotImplementedWidget extends StatelessWidget {
  const _NotImplementedWidget({required this.typeName});

  final String typeName;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A3A4D), width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              color: Colors.white.withOpacity(0.4),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              'type "$typeName" 暂未实现',
              style: TextStyle(
                fontFamily: 'PingFangSC',
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
