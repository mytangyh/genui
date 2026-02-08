// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../services/market_data_service.dart';

/// 大盘概况 Tool（真实数据）
/// 获取三大指数实时行情
class GetMarketOverviewTool extends AiTool<Map<String, Object?>> {
  GetMarketOverviewTool(this._marketService)
      : super(
          name: 'get_market_overview',
          description: '获取大盘实时行情概况，包括上证指数、深证成指、创业板指的实时数据和市场情绪判断。使用真实新浪财经数据。',
          parameters: S.object(properties: {}),
        );

  final MarketDataService _marketService;

  @override
  Future<Map<String, Object?>> invoke(Map<String, Object?> args) async {
    return await _marketService.getMarketOverview();
  }
}
