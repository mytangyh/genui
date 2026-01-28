// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:hexin_ai_ui/hexin_ai_ui.dart';
import 'package:hexin_dsl/hexin_dsl.dart';
import 'package:hexin_highlights/hexin_highlights.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Catalog _catalog = AiUiCatalog.getCatalog();

  final List<Map<String, String>> _tabs = [
    {'id': 'highlights', 'label': '看点'},
    {'id': 'conversation', 'label': '对话'},
    {'id': 'messages', 'label': '消息'},
  ];

  String _headerMarkdown = '';

  @override
  void initState() {
    super.initState();
    // Default to the "messages" tab (index 2)
    _tabController =
        TabController(length: _tabs.length, vsync: this, initialIndex: 2);
    _tabController.addListener(_handleTabChange);
    _updateHeader();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      _updateHeader();
    }
  }

  void _updateHeader() {
    setState(() {
      final currentTabId = _tabs[_tabController.index]['id']!;
      final tabsDsl = _tabs
          .map((tab) => '{"id": "${tab['id']}", "label": "${tab['label']}"}')
          .join(', ');

      _headerMarkdown = '''```dsl
{
  "type": "messageAppBar",
  "props": {
    "selectedTabId": "$currentTabId",
    "tabs": [$tabsDsl],
    "showMenu": true,
    "showVolume": true,
    "showClose": true
  }
}
```''';
    });
  }

  void _handleAction(String actionName, Map<String, dynamic> actionContext) {
    switch (actionName) {
      case 'tab_select':
        final tabId = actionContext['tabId'] as String?;
        if (tabId != null) {
          final index = _tabs.indexWhere((t) => t['id'] == tabId);
          if (index != -1) {
            _tabController.animateTo(index);
          }
        }
      case 'close_tap':
        Navigator.of(context).pop();
      default:
        debugPrint('Action: $actionName, Context: $actionContext');
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
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
        // Reuse existing HighlightsPage from hexin_highlights package
        return const HighlightsPage();
      case 'conversation':
        return const Center(
          child: Text(
            '对话功能暂未开放',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        );
      case 'messages':
        return _buildMessagesEmptyState();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMessagesEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Placeholder for a mascot/image
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.chat_bubble_outline,
            size: 60,
            color: Colors.white24,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '暂无消息',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
