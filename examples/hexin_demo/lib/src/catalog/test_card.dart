// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// A simple test card - minimal component for testing
final testCard = CatalogItem(
  name: 'TestCard',
  dataSchema: S.object(
    properties: {'message': S.string(description: '测试消息')},
    required: ['message'],
  ),
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final String message = data['message'] as String? ?? 'Hello';

    return CoreCatalogItems.card.widgetBuilder(
      CatalogItemContext(
        id: 'test_card_wrapper',
        data: {
          'Card': {'child': 'test_text'},
        },
        buildChild: (childId, [dataContext]) {
          return CoreCatalogItems.text.widgetBuilder(
            CatalogItemContext(
              id: 'test_text',
              data: {
                'Text': {
                  'text': {'literalString': message},
                },
              },
              buildChild: context.buildChild,
              dispatchEvent: context.dispatchEvent,
              buildContext: context.buildContext,
              dataContext: context.dataContext,
              getComponent: context.getComponent,
              surfaceId: context.surfaceId,
            ),
          );
        },
        dispatchEvent: context.dispatchEvent,
        buildContext: context.buildContext,
        dataContext: context.dataContext,
        getComponent: context.getComponent,
        surfaceId: context.surfaceId,
      ),
    );
  },
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "TestCard": {
              "message": "这是一个测试卡片"
            }
          }
        }
      ]
    ''',
  ],
);
