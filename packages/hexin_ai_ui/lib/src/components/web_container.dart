// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import 'dsl_webview.dart';

/// Schema for WebContainer component.
///
/// DSL Example:
/// ```json
/// {
///   "type": "webContainer",
///   "props": {
///     "url": "https://example.com",
///     "defaultHeight": 300
///   }
/// }
/// ```
final _webContainerSchema = S.object(
  description: 'WebContainer 组件，用于在 DSL 中嵌入网页内容',
  properties: {
    'url': S.string(description: '要加载的网页 URL'),
    'defaultHeight': S.number(description: '默认高度（像素）'),
    'enableJS': S.boolean(description: '是否启用 JavaScript（默认 true）'),
    'backgroundColor': S.string(description: '背景颜色，十六进制如 #FFFFFF'),
    'loadingText': S.string(description: '加载中显示的文本'),
  },
  required: ['url'],
);

/// WebContainer component for embedding web content in DSL.
///
/// This component provides a unified DSL interface for WebView,
/// replacing the separate ```web``` code block approach.
final webContainer = CatalogItem(
  name: 'webContainer',
  dataSchema: _webContainerSchema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "webContainer": {
              "url": "https://flutter.dev",
              "defaultHeight": 400
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final String url = data['url'] as String? ?? '';
    final num defaultHeight = data['defaultHeight'] as num? ?? 300;
    final bool enableJS = data['enableJS'] as bool? ?? true;
    final String? backgroundColor = data['backgroundColor'] as String?;
    final String? loadingText = data['loadingText'] as String?;

    // Reuse the existing DslWebView implementation
    return DslWebView(
      url: url,
      height: defaultHeight.toDouble(),
      enableJS: enableJS,
      backgroundColor: backgroundColor,
      loadingText: loadingText,
    );
  },
);
