// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Schema for a simple test card using A2UI protocol.
final _testCardSchema = S.object(
  properties: {
    'title': A2uiSchemas.stringReference(description: '卡片标题'),
    'content': A2uiSchemas.stringReference(description: '卡片内容'),
  },
  required: ['title', 'content'],
);

/// A simple test card using A2UI protocol format.
final simpleTestCard = CatalogItem(
  name: 'SimpleTestCard',
  dataSchema: _testCardSchema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "SimpleTestCard": {
              "title": {
                "literalString": "测试卡片"
              },
              "content": {
                "literalString": "这是一个使用 A2UI 协议的测试卡片内容"
              }
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;

    // Use dataContext.subscribeToString for A2UI protocol
    final ValueNotifier<String?> titleNotifier = context.dataContext
        .subscribeToString(data['title'] as Map<String, Object?>?);
    final ValueNotifier<String?> contentNotifier = context.dataContext
        .subscribeToString(data['content'] as Map<String, Object?>?);

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<String?>(
              valueListenable: titleNotifier,
              builder: (context, title, _) => Text(
                title ?? '无标题',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<String?>(
              valueListenable: contentNotifier,
              builder: (context, content, _) => Text(
                content ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  },
);
