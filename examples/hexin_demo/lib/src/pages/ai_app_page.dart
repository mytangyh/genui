// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:hexin_highlights/hexin_highlights.dart';

/// Catalog containing AI App components.
/// Uses AiUiCatalog plus core catalog items.
Catalog _getAiAppCatalog() {
  return Catalog([
    ...CoreCatalogItems.asCatalog().items,
    ...AiUiCatalog.getAllItems(),
  ]);
}

/// The main AI App page with MarkdownRender pattern.
///
/// The header is rendered from markdown with embedded DSL,
/// enabling flexible remote configuration via API.
class AiAppPage extends StatefulWidget {
  /// Optional custom header markdown.
  final String? headerMarkdown;

  const AiAppPage({super.key, this.headerMarkdown});

  @override
  State<AiAppPage> createState() => _AiAppPageState();
}

class _AiAppPageState extends State<AiAppPage>
    with SingleTickerProviderStateMixin {
  String _headerMarkdown = '';
  late final TabController _tabController;
  late final Catalog _catalog;

  // Tab configuration - can be extracted from header DSL in future
  final List<Map<String, String>> _tabs = [
    {'id': 'highlights', 'label': '看点'},
    {'id': 'watchlist', 'label': '盯盘'},
    {'id': 'stock_picker', 'label': '选股'},
    {'id': 'portfolio', 'label': '组合'},
  ];

  @override
  void initState() {
    super.initState();
    _catalog = _getAiAppCatalog();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _updateHeaderMarkdown();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    // Update immediately when index changes (whether by tap or swipe settlement)
    _updateHeaderMarkdown();
  }

  void _updateHeaderMarkdown() {
    if (widget.headerMarkdown != null) {
      setState(() {
        _headerMarkdown = widget.headerMarkdown!;
      });
      return;
    }

    final currentTabId = _tabs[_tabController.index]['id'];

    // Generate DSL with dynamic selectedTabId
    final newMarkdown = '''
```dsl
{
  "type": "AiAppBar",
  "props": {
    "selectedTabId": "$currentTabId",
    "showMenu": true,
    "tabs": ${_generateTabsJson()},
    "actionButtons": [
      {"label": "今日盈亏", "subLabel": "0.00"},
      {"label": "消息", "badge": "99+", "action": {"name": "open_messages"}}
    ]
  }
}
```
''';

    setState(() {
      _headerMarkdown = newMarkdown;
    });
  }

  String _generateTabsJson() {
    final tabsList = _tabs
        .map((t) => '{"id": "${t['id']}", "label": "${t['label']}"}')
        .join(',');
    return '[$tabsList]';
  }

  void _handleAction(String actionName, Map<String, dynamic> actionContext) {
    if (actionName == 'tab_select') {
      final tabIndex = actionContext['tabIndex'] as int?;
      if (tabIndex != null && tabIndex < _tabController.length) {
        _tabController.animateTo(tabIndex);
      }
      return;
    }

    final snackBar = SnackBar(
      content: Text('Action: $actionName, Context: $actionContext'),
      behavior: SnackBarBehavior.floating,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF191919),
      drawer: const Drawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Header rendered from markdown with embedded DSL
            DslMarkdownSection(
              key: ValueKey(_headerMarkdown),
              markdown: _headerMarkdown,
              catalog: _catalog,
              onAction: _handleAction,
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _tabs.map((tab) {
                  return _buildTabContent(tab['id']!);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(String tabId) {
    switch (tabId) {
      case 'highlights':
        return const HighlightsPage();
      default:
        return _PlaceholderTab(title: tabId);
    }
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String title;

  const _PlaceholderTab({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title 页待开发',
        style: const TextStyle(color: Colors.white54, fontSize: 20),
      ),
    );
  }
}
