// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// DSL parsing and rendering library for hexin demo.
///
/// This library provides utilities for:
/// - Parsing DSL blocks from Markdown text
/// - Rendering DSL definitions to Flutter widgets
///
/// Example usage:
/// ```dart
/// import 'package:hexin_demo/src/dsl/dsl.dart';
///
/// // Parse markdown with DSL blocks
/// final blocks = DslParser.extractBlocks(markdownText);
///
/// // Render the blocks
/// DslBlockList(
///   blocks: blocks,
///   catalog: FinancialCatalog.getDslCatalog(),
///   onAction: (name, context) {
///     print('Action: $name, context: $context');
///   },
/// )
/// ```
library dsl;

export 'dsl_parser.dart';
export 'dsl_surface.dart';
