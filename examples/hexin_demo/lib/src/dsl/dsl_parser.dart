// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

/// A utility class for parsing DSL blocks from Markdown text.
///
/// Extracts code blocks with specific language identifiers (e.g., ```dsl)
/// and parses them as JSON.
///
/// Example usage:
/// ```dart
/// final markdown = '''
/// Some text...
///
/// ```dsl
/// {"type": "ai_message", "props": {"info": "Hello"}}
/// ```
///
/// More text...
/// ''';
///
/// final blocks = DslParser.extractBlocks(markdown);
/// // Returns: [{"type": "ai_message", "props": {"info": "Hello"}}]
/// ```
class DslParser {
  DslParser._();

  /// Extracts all DSL blocks from the given markdown text.
  ///
  /// [markdown] - The markdown text containing DSL code blocks.
  /// [language] - The code block language identifier (default: 'dsl').
  ///
  /// Returns a list of parsed JSON objects from the DSL blocks.
  static List<Map<String, dynamic>> extractBlocks(
    String markdown, {
    String language = 'dsl',
  }) {
    // Match code blocks with the specified language
    // Handles both ``` and ~~~ fences
    final pattern = RegExp(
      '(?:```|~~~)$language\\s*\\n([\\s\\S]*?)(?:```|~~~)',
      multiLine: true,
    );

    final matches = pattern.allMatches(markdown);
    final List<Map<String, dynamic>> results = [];

    for (final match in matches) {
      final jsonString = match.group(1)?.trim();
      if (jsonString == null || jsonString.isEmpty) {
        continue;
      }

      try {
        final decoded = json.decode(jsonString);
        if (decoded is Map<String, dynamic>) {
          results.add(decoded);
        } else if (decoded is List) {
          // If the block contains a list, add each item
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              results.add(item);
            }
          }
        }
      } catch (e) {
        // Skip invalid JSON blocks
        // In production, you might want to log this
        print('DslParser: Failed to parse DSL block: $e');
      }
    }

    return results;
  }

  /// Extracts all code blocks with different languages from markdown.
  ///
  /// Returns a map where keys are language identifiers and values are
  /// lists of parsed content.
  ///
  /// Example:
  /// ```dart
  /// final blocks = DslParser.extractAllBlocks(markdown);
  /// // Returns: {'dsl': [...], 'chart': [...]}
  /// ```
  static Map<String, List<Map<String, dynamic>>> extractAllBlocks(
    String markdown, {
    List<String> languages = const ['dsl'],
  }) {
    final Map<String, List<Map<String, dynamic>>> results = {};

    for (final language in languages) {
      final blocks = extractBlocks(markdown, language: language);
      if (blocks.isNotEmpty) {
        results[language] = blocks;
      }
    }

    return results;
  }

  /// Splits markdown into segments of text and DSL blocks.
  ///
  /// Returns a list of [MarkdownSegment] objects that maintain the original
  /// order of content. This is useful for rendering markdown with embedded
  /// DSL widgets.
  static List<MarkdownSegment> parseSegments(
    String markdown, {
    String language = 'dsl',
  }) {
    final pattern = RegExp(
      '((?:```|~~~)$language\\s*\\n[\\s\\S]*?(?:```|~~~))',
      multiLine: true,
    );

    final List<MarkdownSegment> segments = [];
    int lastEnd = 0;

    for (final match in pattern.allMatches(markdown)) {
      // Add text before this DSL block
      if (match.start > lastEnd) {
        final textBefore = markdown.substring(lastEnd, match.start).trim();
        if (textBefore.isNotEmpty) {
          segments.add(MarkdownSegment.text(textBefore));
        }
      }

      // Parse the DSL block
      final dslMatch = RegExp(
        '(?:```|~~~)$language\\s*\\n([\\s\\S]*?)(?:```|~~~)',
      ).firstMatch(match.group(0)!);

      if (dslMatch != null) {
        final jsonString = dslMatch.group(1)?.trim();
        if (jsonString != null && jsonString.isNotEmpty) {
          try {
            final decoded = json.decode(jsonString);
            if (decoded is Map<String, dynamic>) {
              segments.add(MarkdownSegment.dsl(decoded));
            }
          } catch (e) {
            // If parsing fails, treat as text
            segments.add(MarkdownSegment.text(match.group(0)!));
          }
        }
      }

      lastEnd = match.end;
    }

    // Add remaining text after the last DSL block
    if (lastEnd < markdown.length) {
      final textAfter = markdown.substring(lastEnd).trim();
      if (textAfter.isNotEmpty) {
        segments.add(MarkdownSegment.text(textAfter));
      }
    }

    return segments;
  }
}

/// Represents a segment of parsed markdown content.
///
/// Can be either plain text or a DSL block.
class MarkdownSegment {
  const MarkdownSegment._({required this.type, this.text, this.dsl});

  /// Creates a text segment.
  factory MarkdownSegment.text(String text) {
    return MarkdownSegment._(type: SegmentType.text, text: text);
  }

  /// Creates a DSL segment.
  factory MarkdownSegment.dsl(Map<String, dynamic> dsl) {
    return MarkdownSegment._(type: SegmentType.dsl, dsl: dsl);
  }

  /// The type of this segment.
  final SegmentType type;

  /// The text content (only for text segments).
  final String? text;

  /// The DSL data (only for DSL segments).
  final Map<String, dynamic>? dsl;

  /// Whether this is a text segment.
  bool get isText => type == SegmentType.text;

  /// Whether this is a DSL segment.
  bool get isDsl => type == SegmentType.dsl;
}

/// The type of a markdown segment.
enum SegmentType {
  /// Plain text content.
  text,

  /// DSL block content.
  dsl,
}
