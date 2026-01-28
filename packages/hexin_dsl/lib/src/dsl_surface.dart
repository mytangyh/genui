// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

/// A widget that renders a DSL definition into Flutter widgets.
///
/// This is a simplified version of GenUiSurface that works with the
/// custom DSL format instead of A2UI messages.
///
/// DSL Format:
/// ```json
/// {
///   "version": "1",
///   "children": [
///     {"type": "ai_message", "props": {"info": "Hello"}},
///     {"type": "infoSummaryCard", "props": {...}}
///   ]
/// }
/// ```
///
/// Or single component:
/// ```json
/// {"type": "ai_message", "props": {"info": "Hello"}}
/// ```
class DslSurface extends StatelessWidget {
  /// Creates a DslSurface.
  ///
  /// [dsl] - The DSL definition to render.
  /// [catalog] - The widget catalog to use for building widgets.
  /// [onAction] - Callback for handling user actions (e.g., navigation).
  const DslSurface({
    required this.dsl,
    required this.catalog,
    this.onAction,
    this.spacing = 0.0,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    super.key,
  });

  /// The DSL definition to render.
  final Map<String, dynamic> dsl;

  /// The widget catalog containing component definitions.
  final Catalog catalog;

  /// Callback for handling user actions.
  ///
  /// Called when a component dispatches a UserActionEvent.
  /// The callback receives the action name and context map.
  final void Function(String actionName, Map<String, dynamic> context)?
      onAction;

  /// Spacing between child widgets when rendering a list.
  final double spacing;

  /// Cross axis alignment for the column of children.
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return _DslRenderer(
      dsl: dsl,
      catalog: catalog,
      onAction: onAction,
      spacing: spacing,
      crossAxisAlignment: crossAxisAlignment,
    );
  }
}

class _DslRenderer extends StatelessWidget {
  const _DslRenderer({
    required this.dsl,
    required this.catalog,
    this.onAction,
    this.spacing = 0.0,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final Map<String, dynamic> dsl;
  final Catalog catalog;
  final void Function(String actionName, Map<String, dynamic> context)?
      onAction;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    // Check if it's a container with children
    if (dsl.containsKey('children')) {
      final children = dsl['children'] as List<dynamic>? ?? [];
      return Column(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0 && spacing > 0) SizedBox(height: spacing),
            _buildComponent(context, children[i] as Map<String, dynamic>),
          ],
        ],
      );
    }

    // Single component
    if (dsl.containsKey('type')) {
      return _buildComponent(context, dsl);
    }

    // Unknown format
    return const SizedBox.shrink();
  }

  Widget _buildComponent(BuildContext context, Map<String, dynamic> data) {
    final String? type = data['type'] as String?;
    if (type == null) {
      return const SizedBox.shrink();
    }

    // Find the catalog item for this type
    final item = catalog.items.where((i) => i.name == type).firstOrNull;
    if (item == null) {
      // Unknown component type - show styled placeholder
      return Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A3A4D), width: 1),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction,
                color: Colors.white.withOpacity(0.4),
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                'type "$type" 暂未实现',
                style: TextStyle(
                  fontFamily: 'PingFangSC',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Get props, defaulting to empty map
    final props = data['props'] as Map<String, dynamic>? ?? {};

    // Create a minimal DataModel for this component
    final dataModel = DataModel();

    // Build the widget using the catalog item
    return item.widgetBuilder(
      CatalogItemContext(
        id: data['id'] as String? ?? type,
        data: props,
        buildChild: (childId, [dataContext]) {
          // Look for child in the children array or props
          final childData = _findChild(data, childId);
          if (childData != null) {
            return _buildComponent(context, childData);
          }
          return const SizedBox.shrink();
        },
        dispatchEvent: (event) => _handleEvent(event),
        buildContext: context,
        dataContext: DataContext(dataModel, '/'),
        getComponent: (componentId) => null,
        surfaceId: 'dsl_surface',
      ),
    );
  }

  Map<String, dynamic>? _findChild(
    Map<String, dynamic> parent,
    String childId,
  ) {
    // Check if there's a children array
    final children = parent['children'] as List<dynamic>?;
    if (children != null) {
      for (final child in children) {
        if (child is Map<String, dynamic>) {
          if (child['id'] == childId) {
            return child;
          }
        }
      }
    }

    // Check props for nested children references
    final props = parent['props'] as Map<String, dynamic>?;
    if (props != null) {
      for (final value in props.values) {
        if (value is Map<String, dynamic> && value['id'] == childId) {
          return value;
        }
      }
    }

    return null;
  }

  void _handleEvent(UiEvent event) {
    if (event is UserActionEvent && onAction != null) {
      final context = Map<String, dynamic>.from(event.context);
      onAction!(event.name, context);
    }
  }
}
