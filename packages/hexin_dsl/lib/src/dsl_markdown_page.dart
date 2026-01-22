// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:genui/genui.dart';

import 'dsl_surface.dart';

/// A flexible page component that renders markdown content with embedded DSL.
///
/// Each page is essentially a MarkdownRender that:
/// - Renders standard Markdown syntax (headings, lists, quotes, etc.)
/// - Handles ```dsl``` code blocks as custom DSL components
/// - Handles ```web``` code blocks as WebView components
/// - Supports nested markdownRender components for flexible layouts
///
/// Example usage:
/// ```dart
/// DslMarkdownPage(
///   markdownSections: [markdownContent1, markdownContent2],
///   catalog: MyCatalog.getCatalog(),
///   sectionBuilder: (content, index) => MyCustomWrapper(child: content),
/// )
/// ```
class DslMarkdownPage extends StatelessWidget {
  const DslMarkdownPage({
    required this.markdownSections,
    required this.catalog,
    this.sectionBuilder,
    this.onAction,
    this.padding = EdgeInsets.zero,
    this.backgroundColor,
    super.key,
  });

  /// List of markdown content strings to render.
  /// Each string becomes a section in the page.
  final List<String> markdownSections;

  /// The widget catalog containing component definitions.
  final Catalog catalog;

  /// Optional builder to customize how each section is wrapped.
  /// Receives the rendered content and the section index.
  final Widget Function(Widget content, int index)? sectionBuilder;

  /// Callback for handling user actions from DSL components.
  final void Function(String actionName, Map<String, dynamic> context)?
      onAction;

  /// Padding for the ListView.
  final EdgeInsets padding;

  /// Background color for the page.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: ListView.builder(
        padding: padding,
        itemCount: markdownSections.length,
        itemBuilder: (context, index) {
          final markdown = markdownSections[index];

          final content = DslMarkdownSection(
            markdown: markdown,
            catalog: catalog,
            onAction: onAction,
          );

          if (sectionBuilder != null) {
            return sectionBuilder!(content, index);
          }
          return content;
        },
      ),
    );
  }
}

/// A single section of markdown content with embedded DSL support.
///
/// This widget parses markdown and renders:
/// - Standard markdown as styled text
/// - ```dsl``` blocks as DSL components via the catalog
/// - ```web``` blocks as WebView components
/// - Nested markdownRender DSL components
class DslMarkdownSection extends StatelessWidget {
  const DslMarkdownSection({
    required this.markdown,
    required this.catalog,
    this.onAction,
    super.key,
  });

  /// The markdown content to render.
  final String markdown;

  /// The widget catalog for DSL component lookup.
  final Catalog catalog;

  /// Callback for user actions.
  final void Function(String actionName, Map<String, dynamic> context)?
      onAction;

  @override
  Widget build(BuildContext context) {
    final segments = _parseSegments(markdown);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: segments.map((segment) => _buildSegment(segment)).toList(),
    );
  }

  Widget _buildSegment(_ContentSegment segment) {
    switch (segment.type) {
      case _SegmentType.text:
        return _buildMarkdownText(segment.content!);
      case _SegmentType.dsl:
        return _buildDslComponent(segment.dsl!, segment.language!);
      case _SegmentType.code:
        return _buildCodeBlock(segment.content!, segment.language!);
    }
  }

  Widget _buildMarkdownText(String text) {
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return MarkdownBody(
      data: text,
      styleSheet: _buildStyleSheet(),
      onTapLink: (String text, String? href, String title) {
        if (href != null && onAction != null) {
          onAction!('link_tap', {'url': href, 'text': text});
        }
      },
    );
  }

  Widget _buildDslComponent(Map<String, dynamic> dsl, String language) {
    Map<String, dynamic> surfaceDsl;

    if (language == 'web') {
      // Web blocks are rendered as webview components
      surfaceDsl = {'type': 'webview', 'props': dsl};
    } else {
      // Check for simplyDSL wrapper format and unwrap
      if (dsl.containsKey('simplyDSL') && dsl.containsKey('children')) {
        final children = dsl['children'] as List<dynamic>;
        if (children.isNotEmpty) {
          // Render all children in a column
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children.map((child) {
              if (child is Map<String, dynamic>) {
                return _buildSingleDslComponent(child);
              }
              return const SizedBox.shrink();
            }).toList(),
          );
        }
        return const SizedBox.shrink();
      }
      surfaceDsl = dsl;
    }

    return _buildSingleDslComponent(surfaceDsl);
  }

  Widget _buildSingleDslComponent(Map<String, dynamic> dsl) {
    // Check if it's a nested markdownRender
    final type = dsl['type'] as String?;
    if (type == 'markdownRender') {
      final props = dsl['props'] as Map<String, dynamic>? ?? {};
      final content = props['content'] as String? ?? '';
      // Recursively render nested markdownRender
      return DslMarkdownSection(
        markdown: content,
        catalog: catalog,
        onAction: onAction,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DslSurface(
        dsl: dsl,
        catalog: catalog,
        onAction: onAction,
      ),
    );
  }

  Widget _buildCodeBlock(String code, String language) {
    // Render as standard code block using markdown
    return MarkdownBody(
      data: '```$language\n$code\n```',
      styleSheet: _buildStyleSheet(),
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

  /// Parse markdown content into segments.
  List<_ContentSegment> _parseSegments(String content) {
    final List<_ContentSegment> segments = [];

    // Match code blocks: ```language ... ```
    final pattern = RegExp(r'```(\w+)?\s*\n([\s\S]*?)```', multiLine: true);

    int lastEnd = 0;

    for (final match in pattern.allMatches(content)) {
      // Add text before this code block
      if (match.start > lastEnd) {
        final textBefore = content.substring(lastEnd, match.start);
        if (textBefore.trim().isNotEmpty) {
          segments.add(_ContentSegment.text(textBefore));
        }
      }

      final language = match.group(1) ?? '';
      final codeContent = match.group(2)?.trim() ?? '';

      // Check if it's a DSL or web block
      if (language == 'dsl' || language == 'web') {
        try {
          final decoded = json.decode(codeContent) as Map<String, dynamic>;
          segments.add(_ContentSegment.dsl(decoded, language));
        } catch (_) {
          // JSON parse failed, render as code block
          segments.add(_ContentSegment.code(codeContent, language));
        }
      } else {
        // Other languages - render as code block
        segments.add(_ContentSegment.code(codeContent, language));
      }

      lastEnd = match.end;
    }

    // Add remaining text after last code block
    if (lastEnd < content.length) {
      final textAfter = content.substring(lastEnd);
      if (textAfter.trim().isNotEmpty) {
        segments.add(_ContentSegment.text(textAfter));
      }
    }

    // If no segments found, treat entire content as text
    if (segments.isEmpty) {
      segments.add(_ContentSegment.text(content));
    }

    return segments;
  }
}

/// Internal segment type enum.
enum _SegmentType { text, dsl, code }

/// Internal content segment class.
class _ContentSegment {
  const _ContentSegment._({
    required this.type,
    this.content,
    this.dsl,
    this.language,
  });

  factory _ContentSegment.text(String text) =>
      _ContentSegment._(type: _SegmentType.text, content: text);

  factory _ContentSegment.dsl(Map<String, dynamic> dsl, String language) =>
      _ContentSegment._(type: _SegmentType.dsl, dsl: dsl, language: language);

  factory _ContentSegment.code(String content, String language) =>
      _ContentSegment._(
        type: _SegmentType.code,
        content: content,
        language: language,
      );

  final _SegmentType type;
  final String? content;
  final Map<String, dynamic>? dsl;
  final String? language;
}
