// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:hexin_highlights/hexin_highlights.dart';

/// The main AI App page with 4 tabs and custom top bar.
class AiAppPage extends StatelessWidget {
  const AiAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFF191919),
        drawer: const Drawer(), // Empty sidebar as requested
        appBar: AppBar(
          backgroundColor: const Color(0xFF191919),
          foregroundColor: Colors.white,
          leading: Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          title: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            indicatorColor: Colors
                .transparent, // Hide indicator if strictly following image, or keep specific style
            labelColor: Colors.white,
            labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            unselectedLabelColor: Colors.grey,
            unselectedLabelStyle: TextStyle(fontSize: 16),
            padding: EdgeInsets.zero,
            labelPadding: EdgeInsets.symmetric(horizontal: 12),
            tabs: [
              Tab(text: '看点'),
              Tab(text: '盯盘'),
              Tab(text: '选股'),
              Tab(text: '组合'),
            ],
          ),
          actions: [
            _buildPillButton(
              context,
              label:
                  '今日盈亏\n0.00', // Multiline or styled? Image looks like two lines or label/value. Let's try Row/Column inside.
              isMessage: false,
            ),
            const SizedBox(width: 8),
            _buildPillButton(
              context,
              label: '消息',
              isMessage: true,
              badgeCount: '99+',
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: const TabBarView(
          children: [
            HighlightsPage(),
            _PlaceholderTab(title: '盯盘'),
            _PlaceholderTab(title: '选股'),
            _PlaceholderTab(title: '组合'),
          ],
        ),
      ),
    );
  }

  Widget _buildPillButton(
    BuildContext context, {
    required String label,
    required bool isMessage,
    String? badgeCount,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A35), // Dark blue-ish grey background
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isMessage && label.contains('\n'))
            // Special case for Profit: "今日盈亏" small top, "0.00" big bottom? Or just side by side.
            // Image shows: "今日盈亏" small on top of "0.00" ??? No, looking closely at image:
            // It looks like "今日盈亏 0.00" (single line? or stacked?)
            // Let's assume single line or simple text for now based on "今日盈亏 0.00"
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('今日盈亏',
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
                const Text('0.00',
                    style: TextStyle(fontSize: 12, color: Colors.white)),
              ],
            )
          else
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          if (badgeCount != null) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeCount,
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
    );
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
