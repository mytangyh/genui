// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/genui.dart';

import 'package:hexin_ai_ui/hexin_ai_ui.dart';

/// Financial catalog for the hexin demo application.
class FinancialCatalog {
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
    ]);
  }

  /// Alias for getDslCatalog for backward compatibility.
  static Catalog getCatalog() => getDslCatalog();
}
