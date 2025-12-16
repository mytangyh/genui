// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Schema for alert card component - simple notification style.
final _alertCardSchema = S.object(
  properties: {
    'title': S.string(description: '提醒标题'),
    'message': S.string(description: '提醒内容'),
    'type': S.string(
      description: '类型: info, warning, success',
      enumValues: ['info', 'warning', 'success'],
    ),
  },
  required: ['title', 'message'],
);

/// A simple alert/notification card for market alerts.
final alertCard = CatalogItem(
  name: 'AlertCard',
  dataSchema: _alertCardSchema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "AlertCard": {
              "title": "价格提醒",
              "message": "贵州茅台已突破1700元关口",
              "type": "warning"
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final String title = data['title'] as String? ?? '';
    final String message = data['message'] as String? ?? '';
    final String type = data['type'] as String? ?? 'info';

    final (Color color, IconData icon) = switch (type) {
      'warning' => (Colors.orange, Icons.warning_amber_rounded),
      'success' => (Colors.green, Icons.check_circle_outline),
      _ => (Colors.blue, Icons.info_outline),
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color.withAlpha(200),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  },
);
