// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/genui.dart';

import 'ai_button_list.dart';
import 'ai_event_overview.dart';
import 'ai_message.dart';
import 'auction_anomaly.dart';
import 'banner_carousel.dart';
import 'dsl_webview.dart';
import 'info_summary_card.dart';
import 'market_breadth_bar.dart';
import 'markdown_render.dart';
import 'news_flash_list.dart';
import 'placeholder.dart';
import 'section_header.dart';
import 'stock_quote.dart';
import 'target_header.dart';
import 'trailhead.dart';

/// Financial catalog for the hexin demo application.
class FinancialCatalog {
  /// Returns a minimal catalog for Gemini AI (limited components).
  static Catalog getMinimalCatalog() {
    return Catalog([
      stockQuote, // 显示组件：股票报价
      trailhead, // 交互组件：点击后触发AI生成新UI
    ]);
  }

  /// Returns the full catalog for DSL parsing (all components).
  static Catalog getDslCatalog() {
    return Catalog([
      // DSL 组件
      aiMessage, // AI 消息气泡
      aiButtonList, // AI 按钮组
      aiEventOverview, // AI 事件概览
      auctionAnomaly, // 集合竞价异动
      bannerCarousel, // Banner 轮播图
      infoSummaryCard, // 信息摘要卡片
      newsFlashList, // 快讯列表
      dslWebView, // WebView 组件
      targetHeader, // 标的头部
      placeholder, // 占位符组件
      // 组合容器
      markdownRender, // Markdown 智能渲染容器
      sectionHeader, // 区块头部
      marketBreadthBar, // 涨跌平统计条
      // 通用组件
      stockQuote, // 股票报价
      trailhead, // 交互按钮
    ]);
  }

  /// Alias for getDslCatalog for backward compatibility.
  static Catalog getCatalog() => getDslCatalog();
}
