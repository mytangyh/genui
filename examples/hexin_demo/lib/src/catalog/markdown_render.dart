// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../dsl/dsl.dart';
import 'catalog.dart';

/// Schema for markdown render component.
final _markdownRenderSchema = S.object(
  description: 'Markdown 智能渲染组件，支持标准 Markdown 和嵌入 DSL/Web 组件',
  properties: {
    'content': S.string(description: 'Markdown 内容，支持嵌入 ```dsl 或 ```web 代码块'),
    'backgroundColor': S.string(description: '背景颜色，十六进制如 #1A1F2E'),
    'padding': S.number(description: '内边距（可选，默认12）'),
    'borderRadius': S.number(description: '圆角（可选，默认12）'),
    'enableColoredNumbers': S.boolean(description: '是否启用涨跌色（默认true）'),
  },
  required: ['content'],
);

/// Markdown render component - renders Markdown with embedded DSL widgets.
final markdownRender = CatalogItem(
  name: 'markdownRender',
  dataSchema: _markdownRenderSchema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "markdownRender": {
              "content": "## 大盘统计\\n\\n成交额总计**13214亿**，增+3921亿"
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final String content = data['content'] as String? ?? '';
    final String? backgroundColor = data['backgroundColor'] as String?;
    final num padding = data['padding'] as num? ?? 12;
    final num borderRadius = data['borderRadius'] as num? ?? 12;
    final bool enableColoredNumbers =
        data['enableColoredNumbers'] as bool? ?? true;

    return _MarkdownRender(
      content: content,
      backgroundColor: backgroundColor,
      padding: padding.toDouble(),
      borderRadius: borderRadius.toDouble(),
      enableColoredNumbers: enableColoredNumbers,
      dispatchEvent: context.dispatchEvent,
      componentId: context.id,
    );
  },
);

class _MarkdownRender extends StatelessWidget {
  const _MarkdownRender({
    required this.content,
    this.backgroundColor,
    this.padding = 12,
    this.borderRadius = 12,
    this.enableColoredNumbers = true,
    required this.dispatchEvent,
    required this.componentId,
  });

  final String content;
  final String? backgroundColor;
  final double padding;
  final double borderRadius;
  final bool enableColoredNumbers;
  final void Function(UiEvent event) dispatchEvent;
  final String componentId;

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final hexValue = hex.replaceFirst('#', '');
    try {
      return Color(int.parse('FF$hexValue', radix: 16));
    } catch (_) {
      return null;
    }
  }

  String _unescapeContent(String input) {
    return input.replaceAll('\\n', '\n').replaceAll('\\t', '\t');
  }

  @override
  Widget build(BuildContext context) {
    final unescapedContent = _unescapeContent(content);
    final bgColor = _parseColor(backgroundColor);

    // Parse content into segments
    final segments = _parseContentSegments(unescapedContent);

    Widget child;
    if (segments.length == 1 && segments.first.isText) {
      child = _buildTextWidget(segments.first.text!);
    } else {
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: segments.map((segment) {
          if (segment.isText) {
            return _buildTextWidget(segment.text!);
          } else {
            return _buildDslWidget(segment.dsl!, segment.language!);
          }
        }).toList(),
      );
    }

    if (bgColor != null || padding > 0) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: EdgeInsets.all(padding),
        decoration: bgColor != null
            ? BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(borderRadius),
              )
            : null,
        child: child,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: child,
    );
  }

  /// Build text widget with colored numbers support.
  Widget _buildTextWidget(String text) {
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    // Check if we need to use rich text with colored numbers
    if (enableColoredNumbers && _containsColoredPatterns(text)) {
      return _buildColoredRichText(text);
    }

    // Use simple markdown rendering
    return MarkdownBody(
      data: text,
      styleSheet: _buildStyleSheet(),
      onTapLink: (String text, String? href, String title) {
        if (href != null) {
          dispatchEvent(
            UserActionEvent(
              name: 'link_tap',
              sourceComponentId: componentId,
              context: {'url': href, 'text': text},
            ),
          );
        }
      },
    );
  }

  bool _containsColoredPatterns(String text) {
    // Check for +/- number patterns
    return RegExp(r'[+\-][\d.]+[亿万%]?').hasMatch(text);
  }

  /// Build rich text with colored numbers.
  Widget _buildColoredRichText(String text) {
    // Process the text line by line
    final lines = text.split('\n');
    final List<Widget> widgets = [];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Check for headers
      if (line.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Text(
              line.substring(3),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } else if (line.startsWith('# ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              line.substring(2),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } else if (line.startsWith('### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              line.substring(4),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } else if (line.startsWith('> ')) {
        // Blockquote
        widgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.only(left: 12),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xFF6B8EFF), width: 3),
              ),
            ),
            child: _buildRichTextLine(line.substring(2), isQuote: true),
          ),
        );
      } else if (line.startsWith('---')) {
        // Horizontal rule
        widgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 1,
            color: const Color(0xFF3D4A5D),
          ),
        );
      } else {
        widgets.add(_buildRichTextLine(line));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildRichTextLine(String line, {bool isQuote = false}) {
    final List<InlineSpan> spans = [];

    // Pattern: **bold**, +/-numbers, regular text
    final RegExp pattern = RegExp(
      r'(\*\*([^*]+)\*\*)|([+\-][\d.]+[亿万%元]+)|([^*+\-]+)',
    );

    for (final match in pattern.allMatches(line)) {
      if (match.group(2) != null) {
        // Bold text
        spans.add(
          TextSpan(
            text: match.group(2),
            style: TextStyle(
              color: isQuote ? Colors.white70 : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else if (match.group(3) != null) {
        // Colored number
        final numText = match.group(3)!;
        final isPositive = numText.startsWith('+');
        spans.add(
          TextSpan(
            text: numText,
            style: TextStyle(
              color: isPositive
                  ? const Color(0xFFFF4444)
                  : const Color(0xFF00C853),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      } else if (match.group(4) != null) {
        // Regular text
        spans.add(
          TextSpan(
            text: match.group(4),
            style: TextStyle(
              color: isQuote ? Colors.white70 : Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(text: TextSpan(children: spans)),
    );
  }

  MarkdownStyleSheet _buildStyleSheet() {
    return MarkdownStyleSheet(
      p: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
      h1: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      h2: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      h3: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      h4: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      em: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
      code: const TextStyle(
        color: Color(0xFFE06C75),
        backgroundColor: Color(0xFF2D3A4D),
        fontFamily: 'monospace',
        fontSize: 13,
      ),
      codeblockDecoration: BoxDecoration(
        color: const Color(0xFF1E2A3D),
        borderRadius: BorderRadius.circular(8),
      ),
      blockquote: const TextStyle(color: Colors.white70),
      blockquoteDecoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFF6B8EFF), width: 4)),
      ),
      listBullet: const TextStyle(color: Colors.white),
      tableHead: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      tableBody: const TextStyle(color: Colors.white),
      tableBorder: TableBorder.all(color: const Color(0xFF3D4A5D), width: 1),
      horizontalRuleDecoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF3D4A5D), width: 1)),
      ),
      a: const TextStyle(
        color: Color(0xFF6B8EFF),
        decoration: TextDecoration.underline,
      ),
    );
  }

  Widget _buildDslWidget(Map<String, dynamic> dsl, String language) {
    Map<String, dynamic> surfaceDsl;

    if (language == 'web') {
      surfaceDsl = {'type': 'webview', 'props': dsl};
    } else {
      surfaceDsl = dsl;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DslSurface(
        dsl: surfaceDsl,
        catalog: FinancialCatalog.getDslCatalog(),
        onAction: (actionName, actionContext) {
          dispatchEvent(
            UserActionEvent(
              name: actionName,
              sourceComponentId: componentId,
              context: actionContext,
            ),
          );
        },
      ),
    );
  }

  List<_ContentSegment> _parseContentSegments(String content) {
    final List<_ContentSegment> segments = [];

    final pattern = RegExp(r'```(dsl|web)\s*\n([\s\S]*?)```', multiLine: true);

    int lastEnd = 0;

    for (final match in pattern.allMatches(content)) {
      if (match.start > lastEnd) {
        final textBefore = content.substring(lastEnd, match.start);
        if (textBefore.trim().isNotEmpty) {
          segments.add(_ContentSegment.text(textBefore));
        }
      }

      final language = match.group(1)!;
      final jsonString = match.group(2)?.trim();

      if (jsonString != null && jsonString.isNotEmpty) {
        try {
          final decoded = json.decode(jsonString) as Map<String, dynamic>;
          segments.add(_ContentSegment.dsl(decoded, language));
        } catch (e) {
          segments.add(_ContentSegment.text('> ⚠️ 解析错误: $e'));
        }
      }

      lastEnd = match.end;
    }

    if (lastEnd < content.length) {
      final textAfter = content.substring(lastEnd);
      if (textAfter.trim().isNotEmpty) {
        segments.add(_ContentSegment.text(textAfter));
      }
    }

    if (segments.isEmpty) {
      segments.add(_ContentSegment.text(content));
    }

    return segments;
  }
}

class _ContentSegment {
  const _ContentSegment._({this.text, this.dsl, this.language});

  factory _ContentSegment.text(String text) => _ContentSegment._(text: text);

  factory _ContentSegment.dsl(Map<String, dynamic> dsl, String language) =>
      _ContentSegment._(dsl: dsl, language: language);

  final String? text;
  final Map<String, dynamic>? dsl;
  final String? language;

  bool get isText => text != null;
  bool get isDsl => dsl != null;
}
