// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Schema for placeholder component.
///
/// DSL Example:
/// ```json
/// {
///   "type": "placeholder",
///   "props": {}
/// }
/// ```
final _placeholderSchema = S.object(
  description: '占位符组件，用于表示不支持的组件类型',
  properties: {},
);

/// Placeholder component for unsupported component types.
///
/// This component displays a simple placeholder UI to indicate
/// that a component type is not yet supported.
final placeholder = CatalogItem(
  name: 'placeholder',
  dataSchema: _placeholderSchema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "placeholder": {}
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    return const _Placeholder();
  },
);

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A3A4D), width: 1),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.white.withOpacity(0.5),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '占位符',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
