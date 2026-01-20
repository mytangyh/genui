// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../dsl/dsl.dart';
import 'catalog.dart';

/// Schema for markdown render component.
///
/// This is a smart container that can parse markdown with embedded DSL blocks
/// and render them as native Flutter widgets.
///
/// DSL Example:
/// ```json
/// {
///   "type": "markdownRender",
///   "props": {
///     "content": "```dsl\n{\"type\":\"sectionHeader\",...}\n```\n\n截止此时...\n\n```dsl\n{\"type\":\"marketBreadthBar\",...}\n```"
///   }
/// }
/// ```
final _markdownRenderSchema = S.object(
  description: 'Markdown 渲染容器，支持嵌入 DSL 组件的智能渲染',
  properties: {
    'content': S.string(description: 'Markdown 内容，可包含 ```dsl {...} ``` 代码块'),
    'backgroundColor': S.string(description: '背景颜色，十六进制如 #1E2A3D'),
    'padding': S.number(description: '内边距（可选，默认0）'),
    'borderRadius': S.number(description: '圆角（可选，默认12）'),
  },
  required: ['content'],
);

/// Markdown render component - a smart container for mixed content.
///
/// This component enables arbitrary composition of components by parsing
/// markdown with embedded DSL blocks and rendering them in sequence.
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
              "content": "\`\`\`dsl\\n{\\"type\\":\\"sectionHeader\\",\\"props\\":{\\"title\\":\\"大盘统计\\",\\"action\\":{\\"type\\":\\"image\\",\\"text\\":\\"AI 深度解读\\"}}}\\n\`\`\`\\n\\n截止此时：大盘成交额总计13214亿，较上一日此时增3921亿...\\n\\n\`\`\`dsl\\n{\\"type\\":\\"marketBreadthBar\\",\\"props\\":{\\"up\\":2272,\\"down\\":1499,\\"flat\\":13,\\"limitUp\\":62,\\"limitDown\\":13}}\\n\`\`\`"
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
    final num padding = data['padding'] as num? ?? 0;
    final num borderRadius = data['borderRadius'] as num? ?? 12;

    return _MarkdownRender(
      content: content,
      backgroundColor: backgroundColor,
      padding: padding.toDouble(),
      borderRadius: borderRadius.toDouble(),
      dispatchEvent: context.dispatchEvent,
      componentId: context.id,
    );
  },
);

class _MarkdownRender extends StatelessWidget {
  const _MarkdownRender({
    required this.content,
    this.backgroundColor,
    this.padding = 0,
    this.borderRadius = 12,
    required this.dispatchEvent,
    required this.componentId,
  });

  final String content;
  final String? backgroundColor;
  final double padding;
  final double borderRadius;
  final void Function(UiEvent event) dispatchEvent;
  final String componentId;

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) {
      return const Color(0xFF1A1F2E);
    }
    final hexValue = hex.replaceFirst('#', '');
    try {
      return Color(int.parse('FF$hexValue', radix: 16));
    } catch (_) {
      return const Color(0xFF1A1F2E);
    }
  }

  /// Unescape JSON string escape sequences.
  ///
  /// When content comes from a JSON string, escape sequences like \\n and \\"
  /// need to be converted back to their actual characters.
  String _unescapeContent(String input) {
    return input
        .replaceAll('\\n', '\n')
        .replaceAll('\\t', '\t')
        .replaceAll('\\"', '"')
        .replaceAll('\\\\', '\\');
  }

  @override
  Widget build(BuildContext context) {
    // Unescape the content first (handles JSON escape sequences)
    final unescapedContent = _unescapeContent(content);

    // Parse the content into segments
    final segments = DslParser.parseSegments(unescapedContent);

    // Debug: if no segments found, show the raw content
    if (segments.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: _parseColor(backgroundColor),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Text(
          unescapedContent,
          style: TextStyle(color: Colors.white.withOpacity(0.85)),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: _parseColor(backgroundColor),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: segments.map((segment) {
          if (segment.isDsl) {
            return _buildDslWidget(segment.dsl!);
          } else {
            return _buildMarkdownText(segment.text!);
          }
        }).toList(),
      ),
    );
  }

  Widget _buildDslWidget(Map<String, dynamic> dsl) {
    // Convert to the format expected by DslSurface
    Map<String, dynamic> surfaceDsl;

    if (dsl.containsKey('type')) {
      // Already in {type, props} format
      surfaceDsl = dsl;
    } else if (dsl.containsKey('children')) {
      // Container format with children
      final children = dsl['children'] as List<dynamic>?;
      if (children != null && children.isNotEmpty) {
        surfaceDsl = children.first as Map<String, dynamic>;
      } else {
        return const SizedBox.shrink();
      }
    } else {
      return const SizedBox.shrink();
    }

    return DslSurface(
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
    );
  }

  Widget _buildMarkdownText(String text) {
    // Simple markdown text rendering
    // For full markdown support, you can integrate flutter_markdown package

    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return const SizedBox.shrink();
    }

    // Process the text for basic markdown formatting
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _renderMarkdownText(trimmedText),
    );
  }

  Widget _renderMarkdownText(String text) {
    // Split by newlines and process each line
    final lines = text.split('\n');
    final List<Widget> widgets = [];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Check for headers
      if (line.startsWith('# ')) {
        widgets.add(
          Text(
            line.substring(2),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else if (line.startsWith('## ')) {
        widgets.add(
          Text(
            line.substring(3),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else if (line.startsWith('### ')) {
        widgets.add(
          Text(
            line.substring(4),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else {
        // Regular text with inline formatting
        widgets.add(_buildRichText(line));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildRichText(String text) {
    // Handle bold (**text**) and colored text patterns
    final List<InlineSpan> spans = [];

    // Pattern to match **bold** or colored segments like +3921亿 or -0.56%
    final RegExp pattern = RegExp(
      r'(\*\*([^*]+)\*\*)|([+\-][\d.]+[亿万%]?)|([^*+\-]+)',
    );

    for (final match in pattern.allMatches(text)) {
      if (match.group(2) != null) {
        // Bold text
        spans.add(
          TextSpan(
            text: match.group(2),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else if (match.group(3) != null) {
        // Colored number (positive/negative)
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
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      } else if (match.group(4) != null) {
        // Regular text
        spans.add(
          TextSpan(
            text: match.group(4),
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        );
      }
    }

    return RichText(text: TextSpan(children: spans));
  }
}
