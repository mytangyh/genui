// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import 'dsl_surface.dart';

/// A widget that renders a list of DSL blocks.
///
/// Use this when you have multiple DSL blocks extracted from markdown.
class DslBlockList extends StatelessWidget {
  const DslBlockList({
    required this.blocks,
    required this.catalog,
    this.onAction,
    this.blockSpacing = 16.0,
    this.itemSpacing = 8.0,
    super.key,
  });

  /// The list of DSL blocks to render.
  final List<Map<String, dynamic>> blocks;

  /// The widget catalog to use.
  final Catalog catalog;

  /// Callback for handling user actions.
  final void Function(String actionName, Map<String, dynamic> context)?
      onAction;

  /// Spacing between DSL blocks.
  final double blockSpacing;

  /// Spacing between items within a block.
  final double itemSpacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < blocks.length; i++) ...[
          if (i > 0) SizedBox(height: blockSpacing),
          DslSurface(
            dsl: blocks[i],
            catalog: catalog,
            onAction: onAction,
            spacing: itemSpacing,
          ),
        ],
      ],
    );
  }
}

/// A scrollable wrapper for DslBlockList.
class DslBlockListView extends StatelessWidget {
  const DslBlockListView({
    required this.blocks,
    required this.catalog,
    this.onAction,
    this.blockSpacing = 16.0,
    this.itemSpacing = 8.0,
    this.padding = const EdgeInsets.all(16),
    this.scrollController,
    super.key,
  });

  final List<Map<String, dynamic>> blocks;
  final Catalog catalog;
  final void Function(String actionName, Map<String, dynamic> context)?
      onAction;
  final double blockSpacing;
  final double itemSpacing;
  final EdgeInsets padding;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: scrollController,
      padding: padding,
      itemCount: blocks.length,
      separatorBuilder: (_, __) => SizedBox(height: blockSpacing),
      itemBuilder: (context, index) {
        return DslSurface(
          dsl: blocks[index],
          catalog: catalog,
          onAction: onAction,
          spacing: itemSpacing,
        );
      },
    );
  }
}
