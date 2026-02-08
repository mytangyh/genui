// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../services/market_data_service.dart';

/// 交易历史 Tool
/// 获取今日操作记录，用于盘后复盘
class GetTradingHistoryTool extends AiTool<Map<String, Object?>> {
  GetTradingHistoryTool(this._marketService)
      : super(
          name: 'get_trading_history',
          description: '获取今日交易操作记录，包括：买入卖出详情、盈亏统计、行为标签分析。适用于盘后复盘场景。',
          parameters: S.object(
            properties: {
              'date': S.string(
                description: '可选，日期(YYYY-MM-DD)。默认为今天',
              ),
            },
          ),
        );

  final MarketDataService _marketService;

  @override
  Future<Map<String, Object?>> invoke(Map<String, Object?> args) async {
    return await _marketService.getTradingHistory();
  }
}
