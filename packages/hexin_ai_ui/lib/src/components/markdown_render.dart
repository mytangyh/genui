// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:genui/genui.dart';
import 'package:hexin_dsl/hexin_dsl.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../ai_ui_catalog.dart';

// Note: For DSL rendering, this component uses a callback approach
// to avoid circular dependencies with hexin_dsl package.

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
              "content": "# Markdown 标准演示\\n\\n## 文本样式\\n普通文本包含**粗体**、*斜体*以及`行内代码`。\\n\\n## 列表展示\\n无序列表：\\n- Flutter\\n- GenUI\\n- Markdown\\n\\n有序列表：\\n1. 第一步：编写 DSL\\n2. 第二步：解析渲染\\n3. 第三步：展示结果\\n\\n## 引用与代码\\n> 这是一个引用块，用于强调重要信息。\\n\\n代码块演示：\\n```dart\\nvoid main() {\\n  print(\\"Hello GenUI\\");\\n}\\n```\\n\\n## 分割线\\n---\\n底部说明文本\\n\\n## DSL 组件组合演示\\n\\n```dsl\\n{\\"type\\": \\"infoSummaryCard\\", \\"props\\": {\\"title\\": \\"组合测试\\", \\"summary\\": \\"这是第一个组件\\", \\"action\\": {\\"text\\": \\"操作\\", \\"target\\": \\"route\\"}}}\\n```\\n\\n```dsl\\n{\\"type\\": \\"targetHeader\\", \\"props\\": {\\"timestamp\\": \\"08:16\\", \\"title\\": \\"盘前\\", \\"targetName\\": \\"上证指数\\", \\"targetValue\\": \\"3990.49\\", \\"trend\\": \\"up\\"}}\\n```\\n\\n## WebView 演示\\n\\n```web\\n{\\"url\\": \\"https://m.10jqka.com.cn\\", \\"height\\": 300}\\n```",
              "backgroundColor": "#1A1F2E"
            }
          }
        }
      ]
    ''',
    // BBCode rich text test example
    () => '''
      [
        {
          "id": "bbcode_test",
          "component": {
            "markdownRender": {
              "content": "## 富文本测试\\n\\n大盘成交额[color=down]缩量-657.5亿[/color]，主力净流入[color=up]+84.71亿[/color]\\n\\n[weight=bold]粗体文本测试[/weight]\\n\\n组合测试：[weight=bold][color=up]+100亿[/color][/weight]",
              "backgroundColor": "#1A1F2E"
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
      catalogItemContext: context,
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
    required this.catalogItemContext,
  });

  final String content;
  final String? backgroundColor;
  final double padding;
  final double borderRadius;
  final bool enableColoredNumbers;
  final void Function(UiEvent event) dispatchEvent;
  final String componentId;
  final CatalogItemContext catalogItemContext;

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

    print('markdownRender.build: content length=${unescapedContent.length}');
    print(
      'markdownRender.build: content preview=${unescapedContent.substring(0, unescapedContent.length > 300 ? 300 : unescapedContent.length)}',
    );

    // Parse content into segments
    final segments = parseContentSegments(unescapedContent);
    print('markdownRender.build: ${segments.length} segments parsed');

    Widget child;
    if (segments.length == 1 && segments.first.isText) {
      child = _buildTextWidget(segments.first.text!);
    } else {
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: segments.map((segment) {
          if (segment.isText) {
            print(
              'markdownRender: TEXT segment: ${segment.text!.substring(0, segment.text!.length > 100 ? 100 : segment.text!.length)}',
            );
            return _buildTextWidget(segment.text!);
          } else if (segment.isDsl) {
            print('markdownRender: DSL segment type=${segment.dsl!['type']}');
            return _buildDslWidget(segment.dsl!, segment.language!);
          } else if (segment.isCode) {
            // Render generic code block using standard Markdown
            return MarkdownBody(
              data: '```${segment.language}\n${segment.codeContent}\n```',
              styleSheet: _buildStyleSheet(),
            );
          }
          return const SizedBox.shrink();
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
    final useColoredRichText =
        enableColoredNumbers && _containsColoredPatterns(text);
    print(
      '_buildTextWidget: useColoredRichText=$useColoredRichText, text length=${text.length}',
    );
    print(
      '_buildTextWidget: first 200 chars: ${text.substring(0, text.length > 200 ? 200 : text.length)}',
    );

    if (useColoredRichText) {
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
    // Check for +/- number patterns or BBCode-style tags
    final hasNumbers = RegExp(r'[+\-][\d.]+[亿万%]?').hasMatch(text);
    final hasBBCode = RegExp(r'\[(?:weight|color)=').hasMatch(text);
    final result = hasNumbers || hasBBCode;
    if (hasBBCode) {
      print(
        'BBCode detected in text: ${text.substring(0, text.length > 100 ? 100 : text.length)}...',
      );
    }
    return result;
  }

  /// Build rich text with colored numbers and BBCode support.
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
    // First, parse BBCode-style tags
    final spans = _parseBBCodeText(line, isQuote: isQuote);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(text: TextSpan(children: spans)),
    );
  }

  /// Parse BBCode-style text: [color=up/down], [weight=bold]
  /// up = red, down = green
  List<InlineSpan> _parseBBCodeText(String text, {bool isQuote = false}) {
    final List<InlineSpan> spans = [];

    // Simple BBCode pattern: [tag=value]content[/tag]
    // Match one tag at a time, not greedy
    final RegExp bbCodePattern = RegExp(
      r'\[(color|weight)=(\w+)\]([^\[]*)\[/\1\]',
    );

    String remaining = text;
    int safety = 0;

    while (remaining.isNotEmpty && safety < 100) {
      safety++;
      final match = bbCodePattern.firstMatch(remaining);

      if (match == null) {
        // No more BBCode, add remaining text as-is
        if (remaining.isNotEmpty) {
          spans.addAll(_parseLegacyPatterns(remaining, isQuote: isQuote));
        }
        break;
      }

      // Add text before this match
      if (match.start > 0) {
        final before = remaining.substring(0, match.start);
        spans.addAll(_parseLegacyPatterns(before, isQuote: isQuote));
      }

      final tag = match.group(1)!;
      final value = match.group(2)!;
      final content = match.group(3)!;

      print('BBCode parsed: tag=$tag, value=$value, content=$content');

      // Get style for this tag
      final style = _getBBCodeStyle(tag, value, isQuote);
      if (style != null && content.isNotEmpty) {
        spans.add(
          TextSpan(
            text: content,
            style: TextStyle(
              color: style.color ?? (isQuote ? Colors.white70 : Colors.white),
              fontSize: 14,
              fontWeight: style.fontWeight ?? FontWeight.normal,
            ),
          ),
        );
      } else if (content.isNotEmpty) {
        spans.addAll(_parseLegacyPatterns(content, isQuote: isQuote));
      }

      // Move past this match
      remaining = remaining.substring(match.end);
    }

    // If no spans were added, return plain text
    if (spans.isEmpty && text.isNotEmpty) {
      spans.addAll(_parseLegacyPatterns(text, isQuote: isQuote));
    }

    return spans;
  }

  /// Get TextStyle for a BBCode tag
  TextStyle? _getBBCodeStyle(String tag, String value, bool isQuote) {
    switch (tag) {
      case 'weight':
        if (value == 'bold') {
          return const TextStyle(fontWeight: FontWeight.bold);
        }
        break;
      case 'color':
        if (value == 'up') {
          return const TextStyle(color: Color(0xFFFF4444)); // Red for up
        } else if (value == 'down') {
          return const TextStyle(color: Color(0xFF00C853)); // Green for down
        }
        break;
    }
    return null;
  }

  /// Legacy pattern parsing for +/- numbers and **bold**
  List<InlineSpan> _parseLegacyPatterns(String text, {bool isQuote = false}) {
    final List<InlineSpan> spans = [];

    // Pattern: **bold**, +/-numbers, regular text
    final RegExp pattern = RegExp(
      r'(\*\*([^*]+)\*\*)|([+\-][\d.]+[亿万%元]+)|([^*+\-]+)',
    );

    for (final match in pattern.allMatches(text)) {
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

    return spans;
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
        // Use the comprehensive AI UI catalog to support nesting
        catalog: AiUiCatalog.getCatalog(),
        onAction: (String actionName, Map<String, dynamic> context) {
          dispatchEvent(
            UserActionEvent(
              name: actionName,
              sourceComponentId: componentId,
              context: context,
            ),
          );
        },
      ),
    );
  }
}

@visibleForTesting
List<ContentSegment> parseContentSegments(String content) {
  final List<ContentSegment> segments = [];

  // Capture generic code blocks: ```lang ... ```
  final pattern = RegExp(r'```(\w+)?\s*\n([\s\S]*?)```', multiLine: true);

  int lastEnd = 0;

  for (final match in pattern.allMatches(content)) {
    if (match.start > lastEnd) {
      final textBefore = content.substring(lastEnd, match.start);
      if (textBefore.trim().isNotEmpty) {
        segments.add(ContentSegment.text(textBefore));
      }
    }

    final language = match.group(1) ?? '';
    final codeContent = match.group(2)?.trim() ?? '';

    // Try to parse as DSL if language matches
    if (language == 'dsl' || language == 'web') {
      try {
        // If valid JSON, render as DSL component
        final decoded = json.decode(codeContent) as Map<String, dynamic>;
        segments.add(ContentSegment.dsl(decoded, language));
      } catch (_) {
        // Fallback: JSON parse error, render as generic code block
        segments.add(ContentSegment.code(codeContent, language));
      }
    } else {
      // Unknown language, render as generic code block
      segments.add(ContentSegment.code(codeContent, language));
    }

    lastEnd = match.end;
  }

  if (lastEnd < content.length) {
    final textAfter = content.substring(lastEnd);
    if (textAfter.trim().isNotEmpty) {
      segments.add(ContentSegment.text(textAfter));
    }
  }

  if (segments.isEmpty) {
    segments.add(ContentSegment.text(content));
  }

  return segments;
}

@visibleForTesting
class ContentSegment {
  const ContentSegment._({
    this.text,
    this.dsl,
    this.language,
    this.codeContent,
  });

  factory ContentSegment.text(String text) => ContentSegment._(text: text);

  factory ContentSegment.dsl(Map<String, dynamic> dsl, String language) =>
      ContentSegment._(dsl: dsl, language: language);

  factory ContentSegment.code(String content, String language) =>
      ContentSegment._(codeContent: content, language: language);

  final String? text;
  final Map<String, dynamic>? dsl;
  final String? language;
  final String? codeContent;

  bool get isText => text != null;
  bool get isDsl => dsl != null;
  bool get isCode => codeContent != null;
}
