// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/genui.dart';
import 'package:hexin_ai_ui/hexin_ai_ui.dart';

/// Catalog for highlights feature.
///
/// Provides the complete set of catalog items needed for rendering
/// highlights DSL content.
class HighlightsCatalog {
  HighlightsCatalog._();

  /// Returns the catalog with all highlights-related components.
  static Catalog getCatalog() {
    return Catalog([
      // AI 消息组件
      aiMessage,
      aiButtonList,
      aiEventOverview,

      // 金融信息组件
      auctionAnomaly,
      infoSummaryCard,
      newsFlashList,
      targetHeader,

      // 工具组件
      markdownRender,
      placeholder,
    ]);
  }
}
