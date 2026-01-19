// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Schema for WebView component.
///
/// DSL Example (in ```web code block):
/// ```json
/// {
///   "url": "https://example.com/chart",
///   "height": 300,
///   "enableJS": true
/// }
/// ```
final _webViewSchema = S.object(
  description: 'WebView 组件，用于嵌入网页内容',
  properties: {
    'url': S.string(description: '要加载的网页 URL'),
    'height': S.number(description: '组件高度（像素）'),
    'width': S.number(description: '组件宽度（像素，可选，默认充满父容器）'),
    'enableJS': S.boolean(description: '是否启用 JavaScript（默认 true）'),
    'backgroundColor': S.string(description: '背景颜色，十六进制如 #FFFFFF'),
    'userAgent': S.string(description: '自定义 User-Agent'),
    'loadingText': S.string(description: '加载中显示的文本'),
  },
  required: ['url', 'height'],
);

/// WebView component for displaying web content.
///
/// This component is designed to be used with ```web code blocks in markdown.
final dslWebView = CatalogItem(
  name: 'webview',
  dataSchema: _webViewSchema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "webview": {
              "url": "https://flutter.dev",
              "height": 400,
              "enableJS": true
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final String url = data['url'] as String? ?? '';
    final num height = data['height'] as num? ?? 300;
    final num? width = data['width'] as num?;
    final bool enableJS = data['enableJS'] as bool? ?? true;
    final String? backgroundColor = data['backgroundColor'] as String?;
    final String? loadingText = data['loadingText'] as String?;

    return DslWebView(
      url: url,
      height: height.toDouble(),
      width: width?.toDouble(),
      enableJS: enableJS,
      backgroundColor: backgroundColor,
      loadingText: loadingText,
    );
  },
);

/// WebView widget implementation.
class DslWebView extends StatefulWidget {
  const DslWebView({
    required this.url,
    required this.height,
    this.width,
    this.enableJS = true,
    this.backgroundColor,
    this.loadingText,
    super.key,
  });

  final String url;
  final double height;
  final double? width;
  final bool enableJS;
  final String? backgroundColor;
  final String? loadingText;

  @override
  State<DslWebView> createState() => _DslWebViewState();
}

class _DslWebViewState extends State<DslWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    // WebView is not supported on web platform
    if (kIsWeb) {
      setState(() {
        _error = 'WebView is not supported on web platform';
        _isLoading = false;
      });
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(
        widget.enableJS ? JavaScriptMode.unrestricted : JavaScriptMode.disabled,
      )
      ..setBackgroundColor(_parseColor(widget.backgroundColor))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(() {
                _error = error.description;
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) {
      return Colors.white;
    }
    final hexValue = hex.replaceFirst('#', '');
    try {
      return Color(int.parse('FF$hexValue', radix: 16));
    } catch (_) {
      return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: _parseColor(widget.backgroundColor),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    // Show error state
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.url,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Show WebView on non-web platforms
    if (!kIsWeb) {
      return Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: _parseColor(widget.backgroundColor),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.blue),
                    if (widget.loadingText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.loadingText!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      );
    }

    // Fallback for web platform
    return Center(
      child: Text(
        'WebView: ${widget.url}',
        style: TextStyle(color: Colors.white.withOpacity(0.7)),
      ),
    );
  }
}
