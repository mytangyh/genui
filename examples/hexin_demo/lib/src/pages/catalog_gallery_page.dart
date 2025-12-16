// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import '../catalog/catalog.dart';

/// Catalog gallery page.
class CatalogGalleryPage extends StatefulWidget {
  const CatalogGalleryPage({super.key});

  @override
  State<CatalogGalleryPage> createState() => _CatalogGalleryPageState();
}

class _CatalogGalleryPageState extends State<CatalogGalleryPage>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return DebugCatalogView(
      catalog: FinancialCatalog.getCatalog(),
      itemHeight: 400, // Give components enough height to render
      onSubmit: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('组件交互: ${message.parts.first}'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
