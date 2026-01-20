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

  /// Extracts code blocks with different languages in document order.
  ///
  /// [markdown] - The markdown text containing code blocks.
  /// [languages] - List of language identifiers to extract.
  /// [transformer] - Optional function to transform specific language blocks.
  ///
  /// Returns a list of parsed JSON objects (or transformed objects) in the order
  /// they appear in the markdown.
  static List<Map<String, dynamic>> extractMixedBlocks(
    String markdown, {
    required List<String> languages,
    Map<String, dynamic> Function(Map<String, dynamic> data, String language)?
    transformer,
  }) {
    if (languages.isEmpty) return [];

    final languagePattern = languages.join('|');
    // Match code blocks with any of the specified languages
    final pattern = RegExp(
      '(?:```|~~~)(?:$languagePattern)\\s*\\n([\\s\\S]*?)(?:```|~~~)',
      multiLine: true,
    );

    final matches = pattern.allMatches(markdown);
    final List<Map<String, dynamic>> results = [];

    for (final match in matches) {
      // We need to re-parse the match to find out WHICH language verified it
      // Or we can just use a slightly different regex to capture the language
      final fullMatch = match.group(0)!;
      final headerMatch = RegExp(
        '(?:```|~~~)(?:($languagePattern))\\s*\\n',
      ).firstMatch(fullMatch);
      final language = headerMatch?.group(1);

      if (language == null) continue;

      final jsonString = match.group(1)?.trim();
      if (jsonString == null || jsonString.isEmpty) {
        continue;
      }

      try {
        final decoded = json.decode(jsonString);
        dynamic data;

        if (decoded is Map<String, dynamic>) {
          data = decoded;
        } else if (decoded is List) {
          // If the block contains a list, treat the whole list as one unit if transformer expects it?
          // The original behavior flattened lists. Let's stick to map extraction for the primary use case.
          // But wait, DslDemoPage expects a list of maps.
          // If a single block has a list, should we expand it?
          // If we expand it, we lose the "language" context for the individual items if we are just returning a flat list.
          // However, the mixed extraction implies we want to maintain block integrity usually.
          // BUT, existing extractBlocks flattens lists. Let's do the same for consistency,
          // applying the transformer to each item.
          data = decoded;
        }

        if (data is Map<String, dynamic>) {
          if (transformer != null) {
            results.add(transformer(data, language));
          } else {
            results.add(data);
          }
        } else if (data is List) {
          for (final item in data) {
            if (item is Map<String, dynamic>) {
              if (transformer != null) {
                results.add(transformer(item, language));
              } else {
                results.add(item);
              }
            }
          }
        }
      } catch (e) {
        print('DslParser: Failed to parse $language block: $e');
      }
    }

    return results;
  }

  /// Extracts all code blocks with different languages from markdown.

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
