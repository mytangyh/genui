// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Schema for AI event overview component.
final _aiEventOverviewSchema = S.object(
  description: 'AI事件概览组件',
  properties: {'event_id': S.string(description: '事件ID')},
  required: ['event_id'],
);

/// AI event overview catalog item (placeholder).
final aiEventOverview = CatalogItem(
  name: 'ai_event_overview',
  dataSchema: _aiEventOverviewSchema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "ai_event_overview": {
              "event_id": "现货黄金突破4750美元！再创新高"
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    return const _AiEventOverviewPlaceholder();
  },
);

class _AiEventOverviewPlaceholder extends StatelessWidget {
  const _AiEventOverviewPlaceholder();

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
          'AI事件概览组件暂未实现',
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
