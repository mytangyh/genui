// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/genui.dart';

import 'components/ai_app_bar.dart';
import 'components/ai_button_list.dart';
import 'components/ai_event_overview.dart';
import 'components/ai_message.dart';
import 'components/auction_anomaly.dart';
import 'components/banner_carousel.dart';
import 'components/dsl_webview.dart';
import 'components/info_summary_card.dart';
import 'components/market_breadth_bar.dart';
import 'components/markdown_render.dart';
import 'components/news_flash_list.dart';
import 'components/pill_button.dart';
import 'components/placeholder.dart';
import 'components/section_header.dart';
import 'components/stock_quote.dart';
import 'components/target_header.dart';
import 'components/trailhead.dart';

/// Centralized catalog provider for hexin_ai_ui components.
///
/// This class provides a unified way to access all catalog items
/// defined in this package.
class AiUiCatalog {
  AiUiCatalog._();

  /// Returns the complete catalog with all hexin_ai_ui components.
  static Catalog getCatalog() {
    return Catalog(getAllItems());
  }

  /// Returns all catalog items as a list.
  static List<CatalogItem> getAllItems() {
    return [
      // AI 消息组件
      aiMessage,
      aiButtonList,
      aiEventOverview,

      // 金融信息组件
      auctionAnomaly,
      bannerCarousel,
      infoSummaryCard,
      newsFlashList,
      targetHeader,
      stockQuote,

      // 工具组件
      placeholder,
      dslWebView,

      // 组合容器
      markdownRender,
      sectionHeader,
      marketBreadthBar,

      // 推荐/交互组件
      trailhead,

      // AI App 组件
      pillButton,
      aiAppBar,
    ];
  }
}
