// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import 'src/catalog/catalog.dart';
import 'src/pages/advisor_page.dart';
import 'src/pages/dsl_demo_page.dart';

void main() {
  runApp(const HexinDemoApp());
}

/// Main application widget for hexin_demo.
class HexinDemoApp extends StatelessWidget {
  const HexinDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '核心投顾 Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainTabView(),
    );
  }
}

/// Main tab view with advisor, catalog gallery, and DSL demo.
class MainTabView extends StatelessWidget {
  const MainTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('核心投顾 - 智能投资助手'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.chat), text: '投资顾问'),
              Tab(icon: Icon(Icons.dashboard), text: '组件画廊'),
              Tab(icon: Icon(Icons.code), text: 'DSL Demo'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [AdvisorPage(), CatalogTab(), DslDemoPage()],
        ),
      ),
    );
  }
}

/// Catalog tab - exact copy from travel_app
class CatalogTab extends StatefulWidget {
  const CatalogTab({super.key});

  @override
  State<CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<CatalogTab>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DebugCatalogView(catalog: FinancialCatalog.getCatalog());
  }

  @override
  bool get wantKeepAlive => true;
}
