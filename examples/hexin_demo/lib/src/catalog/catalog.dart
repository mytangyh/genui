// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/genui.dart';

import 'stock_quote.dart';
import 'trailhead.dart';

/// Financial catalog for the hexin demo application.
///
/// IMPORTANT: Keep this list minimal (2 components) to avoid Gemini API
/// schema complexity limits.
class FinancialCatalog {
  /// Returns a minimal catalog showing both display and interaction.
  static Catalog getCatalog() {
    return Catalog([
      stockQuote, // 显示组件：股票报价
      trailhead, // 交互组件：点击后触发AI生成新UI
    ]);
  }
}
