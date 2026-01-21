// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final _tabSchema = S.object(
  properties: {
    'id': S.string(description: 'Unique tab identifier'),
    'label': S.string(description: 'Tab display label'),
  },
  required: ['id', 'label'],
);

final _actionButtonSchema = S.object(
  properties: {
    'label': S.string(description: 'Button label'),
    'subLabel': S.string(description: 'Secondary label'),
    'badge': S.string(description: 'Badge text'),
    'action': A2uiSchemas.action(description: 'Action on tap'),
  },
  required: ['label'],
);

final _schema = S.object(
  properties: {
    'showMenu': S.boolean(
      description: 'Whether to show the menu icon on the left',
    ),
    'tabs': S.list(
      description: 'List of tab configurations',
      items: _tabSchema,
    ),
    'actionButtons': S.list(
      description: 'List of action button configurations',
      items: _actionButtonSchema,
    ),
    'menuAction': A2uiSchemas.action(
      description: 'Action when menu icon is tapped',
    ),
  },
  required: ['tabs'],
);

extension type _TabData.fromMap(Map<String, Object?> _json) {
  String get id => _json['id'] as String;
  String get label => _json['label'] as String;
}

extension type _ActionButtonData.fromMap(Map<String, Object?> _json) {
  String get label => _json['label'] as String;
  String? get subLabel => _json['subLabel'] as String?;
  String? get badge => _json['badge'] as String?;
  JsonMap? get action => _json['action'] as JsonMap?;
}

extension type _AiAppBarData.fromMap(Map<String, Object?> _json) {
  bool get showMenu => (_json['showMenu'] as bool?) ?? true;
  List<_TabData> get tabs => (_json['tabs'] as List)
      .cast<Map<String, Object?>>()
      .map(_TabData.fromMap)
      .toList();
  List<_ActionButtonData> get actionButtons =>
      ((_json['actionButtons'] as List?) ?? [])
          .cast<Map<String, Object?>>()
          .map(_ActionButtonData.fromMap)
          .toList();
  JsonMap? get menuAction => _json['menuAction'] as JsonMap?;
}

/// A configurable app bar for AI App interfaces.
///
/// Renders a menu icon, scrollable tabs, and action buttons based on
/// configuration data. This component is designed for use where the
/// app bar structure can be dynamically defined via DSL.
final aiAppBar = CatalogItem(
  name: 'AiAppBar',
  dataSchema: _schema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "AiAppBar": {
              "showMenu": true,
              "tabs": [
                {"id": "highlights", "label": "看点"},
                {"id": "watchlist", "label": "盯盘"},
                {"id": "stock_picker", "label": "选股"},
                {"id": "portfolio", "label": "组合"}
              ],
              "actionButtons": [
                {"label": "今日盈亏", "subLabel": "0.00"},
                {"label": "消息", "badge": "99+"}
              ]
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (itemContext) {
    final data = _AiAppBarData.fromMap(
      itemContext.data as Map<String, Object?>,
    );
    return _AiAppBar(
      showMenu: data.showMenu,
      tabs: data.tabs,
      actionButtons: data.actionButtons,
      menuAction: data.menuAction,
      widgetId: itemContext.id,
      dispatchEvent: itemContext.dispatchEvent,
    );
  },
);

class _AiAppBar extends StatelessWidget {
  const _AiAppBar({
    required this.showMenu,
    required this.tabs,
    required this.actionButtons,
    this.menuAction,
    required this.widgetId,
    required this.dispatchEvent,
  });

  final bool showMenu;
  final List<_TabData> tabs;
  final List<_ActionButtonData> actionButtons;
  final JsonMap? menuAction;
  final String widgetId;
  final DispatchEventCallback dispatchEvent;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: const Color(0xFF191919),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            if (showMenu)
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: _handleMenuTap,
              ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: tabs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final tab = entry.value;
                    final isFirst = index == 0;
                    return GestureDetector(
                      onTap: () => _handleTabTap(index, tab.id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          tab.label,
                          style: TextStyle(
                            color: isFirst ? Colors.white : Colors.grey,
                            fontSize: isFirst ? 18 : 16,
                            fontWeight:
                                isFirst ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            ...actionButtons.map((btn) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildPillButton(btn),
                )),
          ],
        ),
      ),
    );
  }

  void _handleTabTap(int index, String tabId) {
    dispatchEvent(
      UserActionEvent(
        name: 'tab_select',
        sourceComponentId: widgetId,
        context: {'tabIndex': index, 'tabId': tabId},
      ),
    );
  }

  void _handleMenuTap() {
    if (menuAction == null) return;
    final name = menuAction!['name'] as String?;
    if (name == null) return;
    dispatchEvent(
      UserActionEvent(
        name: name,
        sourceComponentId: widgetId,
        context: {},
      ),
    );
  }

  Widget _buildPillButton(_ActionButtonData btn) {
    return GestureDetector(
      onTap: () => _handleButtonTap(btn),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A35),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (btn.subLabel != null)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    btn.label,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    btn.subLabel!,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              )
            else
              Text(
                btn.label,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            if (btn.badge != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  btn.badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleButtonTap(_ActionButtonData btn) {
    if (btn.action == null) return;
    final name = btn.action!['name'] as String?;
    if (name == null) return;
    dispatchEvent(
      UserActionEvent(
        name: name,
        sourceComponentId: widgetId,
        context: {'buttonId': btn.label},
      ),
    );
  }
}
