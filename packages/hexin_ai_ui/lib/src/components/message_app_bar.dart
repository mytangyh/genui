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

final _schema = S.object(
  properties: {
    'showMenu': S.boolean(
      description: 'Whether to show the menu icon on the left',
    ),
    'showVolume': S.boolean(
      description: 'Whether to show the volume icon on the right',
    ),
    'showClose': S.boolean(
      description: 'Whether to show the close button on the right',
    ),
    'tabs': S.list(
      description: 'List of tab configurations',
      items: _tabSchema,
    ),
    'selectedTabId': S.string(
      description: 'ID of the currently selected tab. Defaults to first tab.',
    ),
  },
  required: ['tabs'],
);

extension type _TabData.fromMap(Map<String, Object?> _json) {
  String get id => _json['id'] as String;
  String get label => _json['label'] as String;
}

extension type _MessageAppBarData.fromMap(Map<String, Object?> _json) {
  bool get showMenu => (_json['showMenu'] as bool?) ?? true;
  bool get showVolume => (_json['showVolume'] as bool?) ?? true;
  bool get showClose => (_json['showClose'] as bool?) ?? true;
  List<_TabData> get tabs => (_json['tabs'] as List)
      .cast<Map<String, Object?>>()
      .map(_TabData.fromMap)
      .toList();
  String? get selectedTabId => _json['selectedTabId'] as String?;
}

/// A configurable message app bar for conversation page.
///
/// Renders pill-styled tabs with menu, volume, and close buttons.
/// Designed for the message/conversation page interface.
final messageAppBar = CatalogItem(
  name: 'messageAppBar',
  dataSchema: _schema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "messageAppBar": {
              "showMenu": true,
              "showVolume": true,
              "showClose": true,
              "selectedTabId": "messages",
              "tabs": [
                {"id": "highlights", "label": "看点"},
                {"id": "conversation", "label": "对话"},
                {"id": "messages", "label": "消息"}
              ]
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (itemContext) {
    final data = _MessageAppBarData.fromMap(
      itemContext.data as Map<String, Object?>,
    );
    return _MessageAppBar(
      showMenu: data.showMenu,
      showVolume: data.showVolume,
      showClose: data.showClose,
      tabs: data.tabs,
      selectedTabId: data.selectedTabId,
      widgetId: itemContext.id,
      dispatchEvent: itemContext.dispatchEvent,
    );
  },
);

class _MessageAppBar extends StatelessWidget {
  const _MessageAppBar({
    required this.showMenu,
    required this.showVolume,
    required this.showClose,
    required this.tabs,
    this.selectedTabId,
    required this.widgetId,
    required this.dispatchEvent,
  });

  final bool showMenu;
  final bool showVolume;
  final bool showClose;
  final List<_TabData> tabs;
  final String? selectedTabId;
  final String widgetId;
  final DispatchEventCallback dispatchEvent;

  @override
  Widget build(BuildContext context) {
    final currentTabId =
        selectedTabId ?? (tabs.isNotEmpty ? tabs.first.id : '');

    return SafeArea(
      bottom: false,
      child: Container(
        color: const Color(0xFF191919),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            // Left: Menu icon
            if (showMenu)
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: _handleMenuTap,
              ),

            // Center: Separated pill tabs
            Expanded(
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: tabs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final tab = entry.value;
                    final isSelected = tab.id == currentTabId;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => _handleTabTap(index, tab.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFE53935)
                                : const Color(0xFF2A2A35),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tab.label,
                            style: TextStyle(
                              color:
                                  isSelected ? Colors.white : Colors.grey[400],
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Right: Volume and Close buttons
            if (showVolume)
              IconButton(
                icon: const Icon(Icons.volume_up, color: Colors.white),
                onPressed: _handleVolumeTap,
              ),
            if (showClose)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _handleCloseTap,
              ),
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
    dispatchEvent(
      UserActionEvent(
        name: 'menu_tap',
        sourceComponentId: widgetId,
        context: {},
      ),
    );
  }

  void _handleVolumeTap() {
    dispatchEvent(
      UserActionEvent(
        name: 'volume_tap',
        sourceComponentId: widgetId,
        context: {},
      ),
    );
  }

  void _handleCloseTap() {
    dispatchEvent(
      UserActionEvent(
        name: 'close_tap',
        sourceComponentId: widgetId,
        context: {},
      ),
    );
  }
}
