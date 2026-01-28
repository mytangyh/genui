// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final _schema = S.object(
  properties: {
    'label': S.string(description: 'Primary button label'),
    'subLabel':
        S.string(description: 'Secondary label displayed below primary'),
    'badge': S.string(description: 'Badge text like "99+"'),
    'action': A2uiSchemas.action(
      description: 'Action to perform when button is tapped',
    ),
  },
  required: ['label'],
);

extension type _PillButtonData.fromMap(Map<String, Object?> _json) {
  factory _PillButtonData({
    required String label,
    String? subLabel,
    String? badge,
    JsonMap? action,
  }) =>
      _PillButtonData.fromMap({
        'label': label,
        'subLabel': subLabel,
        'badge': badge,
        'action': action,
      });

  String get label => _json['label'] as String;
  String? get subLabel => _json['subLabel'] as String?;
  String? get badge => _json['badge'] as String?;
  JsonMap? get action => _json['action'] as JsonMap?;
}

/// A pill-shaped action button component for AI App interfaces.
///
/// Displays a rounded button with optional secondary label and badge.
/// Commonly used in app bars for actions like "今日盈亏" or "消息".
final pillButton = CatalogItem(
  name: 'pillButton',
  dataSchema: _schema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "pillButton": {
              "label": "今日盈亏",
              "subLabel": "0.00"
            }
          }
        }
      ]
    ''',
    () => '''
      [
        {
          "id": "root",
          "component": {
            "pillButton": {
              "label": "消息",
              "badge": "99+",
              "action": {"name": "open_messages"}
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (itemContext) {
    final data = _PillButtonData.fromMap(
      itemContext.data as Map<String, Object?>,
    );
    return _PillButton(
      label: data.label,
      subLabel: data.subLabel,
      badge: data.badge,
      action: data.action,
      widgetId: itemContext.id,
      dispatchEvent: itemContext.dispatchEvent,
    );
  },
);

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    this.subLabel,
    this.badge,
    this.action,
    required this.widgetId,
    required this.dispatchEvent,
  });

  final String label;
  final String? subLabel;
  final String? badge;
  final JsonMap? action;
  final String widgetId;
  final DispatchEventCallback dispatchEvent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A35),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildContent(),
            if (badge != null) ...[
              const SizedBox(width: 4),
              _buildBadge(),
            ],
          ],
        ),
      ),
    );
  }

  void _handleTap() {
    if (action == null) return;
    final name = action!['name'] as String?;
    if (name == null) return;
    dispatchEvent(
      UserActionEvent(
        name: name,
        sourceComponentId: widgetId,
        context: {},
      ),
    );
  }

  Widget _buildContent() {
    if (subLabel != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          Text(
            subLabel!,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ],
      );
    }
    return Text(
      label,
      style: const TextStyle(color: Colors.white, fontSize: 13),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        badge!,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
