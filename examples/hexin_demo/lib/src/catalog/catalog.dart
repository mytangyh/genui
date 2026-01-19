// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/genui.dart';

import 'ai_message.dart';
import 'dsl_webview.dart';
import 'info_summary_card.dart';
import 'news_flash_list.dart';
import 'stock_quote.dart';
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
      infoSummaryCard, // 信息摘要卡片
      newsFlashList, // 快讯列表
      dslWebView, // WebView 组件
      // 通用组件
      stockQuote, // 股票报价
      trailhead, // 交互按钮
    ]);
  }

  /// Alias for getDslCatalog for backward compatibility.
  static Catalog getCatalog() => getDslCatalog();
}
