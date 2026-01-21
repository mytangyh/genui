// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:hexin_ai_ui/hexin_ai_ui.dart';
import 'package:hexin_dsl/hexin_dsl.dart';
import 'package:hexin_highlights/hexin_highlights.dart';

/// Default DSL configuration for the AI App bar.
///
/// This can be replaced with API-fetched config in the future.
/// Format follows DslSurface expectations: {type: 'Component', props: {...}}
const _defaultAppBarDsl = <String, dynamic>{
  'type': 'AiAppBar',
  'props': {
    'showMenu': true,
    'tabs': [
      {'id': 'highlights', 'label': '看点'},
      {'id': 'watchlist', 'label': '盯盘'},
      {'id': 'stock_picker', 'label': '选股'},
      {'id': 'portfolio', 'label': '组合'},
    ],
    'actionButtons': [
      {'label': '今日盈亏', 'subLabel': '0.00'},
      {
        'label': '消息',
        'badge': '99+',
        'action': {'name': 'open_messages'}
      },
    ],
  },
};

/// Catalog containing AI App specific components.
Catalog _getAiAppCatalog() {
  return Catalog([
    ...CoreCatalogItems.asCatalog().items,
    aiAppBar,
    pillButton,
  ]);
}

/// The main AI App page with DSL-driven configurable top bar.
///
/// The app bar is rendered from DSL configuration, enabling future
/// remote configuration via API.
class AiAppPage extends StatefulWidget {
  /// Optional custom DSL config for the app bar.
  final Map<String, dynamic>? appBarConfig;

  const AiAppPage({super.key, this.appBarConfig});

  @override
  State<AiAppPage> createState() => _AiAppPageState();
}

class _AiAppPageState extends State<AiAppPage>
    with SingleTickerProviderStateMixin {
  late final Map<String, dynamic> _appBarConfig;
  late final TabController _tabController;
  late final Catalog _catalog;

  @override
  void initState() {
    super.initState();
    _appBarConfig = widget.appBarConfig ?? _defaultAppBarDsl;
    _catalog = _getAiAppCatalog();

    // Extract tabs from props
    final props = _appBarConfig['props'] as Map<String, dynamic>? ?? {};
    final tabs = props['tabs'] as List? ?? [];
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    final props = _appBarConfig['props'] as Map<String, dynamic>? ?? {};
    final tabs = props['tabs'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF191919),
      drawer: const Drawer(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: DslSurface(
          dsl: _appBarConfig,
          catalog: _catalog,
          onAction: _handleAction,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: tabs.map((tab) {
          final tabId = (tab as Map<String, dynamic>)['id'] as String;
          return _buildTabContent(tabId);
        }).toList(),
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
