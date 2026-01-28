// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:hexin_highlights/hexin_highlights.dart';

/// Catalog containing AI App components.
/// Uses AiUiCatalog plus core catalog items.
Catalog _getMessagePageCatalog() {
  return Catalog([
    ...CoreCatalogItems.asCatalog().items,
    ...AiUiCatalog.getAllItems(),
  ]);
}

/// The message/conversation page with tabs: 看点, 对话, 消息.
///
/// Accessed from AiAppPage by tapping the "消息" button.
/// Header is rendered from markdown with embedded DSL for remote configuration.
class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage>
    with SingleTickerProviderStateMixin {
  String _headerMarkdown = '';
  late final TabController _tabController;
  late final Catalog _catalog;

  // Tab configuration - 看点, 对话, 消息
  final List<Map<String, String>> _tabs = [
    {'id': 'highlights', 'label': '看点'},
    {'id': 'conversation', 'label': '对话'},
    {'id': 'messages', 'label': '消息'},
  ];

  @override
  void initState() {
    super.initState();
    _catalog = _getMessagePageCatalog();
    // Default to "消息" tab (index 2)
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: 2,
    );
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
    _updateHeaderMarkdown();
  }

  void _updateHeaderMarkdown() {
    final currentTabId = _tabs[_tabController.index]['id'];

    final newMarkdown = '''
```dsl
{
  "type": "MessageAppBar",
  "props": {
    "selectedTabId": "$currentTabId",
    "showMenu": true,
    "showVolume": true,
    "showClose": true,
    "tabs": ${_generateTabsJson()}
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
    switch (actionName) {
      case 'tab_select':
        final tabIndex = actionContext['tabIndex'] as int?;
        if (tabIndex != null && tabIndex < _tabController.length) {
          _tabController.animateTo(tabIndex);
        }
      case 'close_tap':
        Navigator.of(context).pop();
      case 'menu_tap':
      case 'volume_tap':
        final snackBar = SnackBar(
          content: Text('Action: $actionName'),
          behavior: SnackBarBehavior.floating,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF191919),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Column(
              children: [
                // Header rendered from markdown with embedded DSL
                DslMarkdownSection(
                  key: ValueKey(_headerMarkdown),
                  markdown: _headerMarkdown,
                  catalog: _catalog,
                  onAction: _handleAction,
                ),
                // Tab content with padding to avoid overlap with bottom card
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 110),
                    child: TabBarView(
                      controller: _tabController,
                      children: _tabs.map((tab) {
                        return _buildTabContent(tab['id']!);
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            // Floating Conversation Card at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DslMarkdownSection(
                markdown: '''```dsl
{
  "type": "conversationCard",
  "props": {
    "onOrderTap": "client://trade/order",
    "onMicTap": "client://voice/icon",
    "onKeyboardTap": "client://input/keyboard"
  }
}
```''',
                catalog: _catalog,
                onAction: _handleAction,
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
      case 'conversation':
        return const _PlaceholderTab(title: '对话');
      case 'messages':
        return const _EmptyMessageState();
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

/// Empty state for messages tab with mascot image.
class _EmptyMessageState extends StatelessWidget {
  const _EmptyMessageState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mascot placeholder - would be replaced with actual mascot image
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A35),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.pets,
              size: 60,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              '暂无消息',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
