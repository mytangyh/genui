// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../services/market_data_service.dart';

/// 实时行情 Tool
/// 获取股票实时行情数据（真实数据）
class GetRealTimeQuoteTool extends AiTool<Map<String, Object?>> {
  GetRealTimeQuoteTool(this._marketService)
      : super(
          name: 'get_realtime_quote',
          description: '获取股票实时行情数据，包括：最新价、涨跌幅、成交量等。使用真实新浪财经数据。',
          parameters: S.object(
            properties: {
              'stockCode': S.string(
                description: '股票代码，如 600519（沪市）或 000001（深市）',
              ),
            },
            required: ['stockCode'],
          ),
        );

  final MarketDataService _marketService;

  @override
  Future<Map<String, Object?>> invoke(Map<String, Object?> args) async {
    final stockCode = args['stockCode'] as String;
    final quote = await _marketService.getRealTimeQuote(stockCode);
    if (quote != null) {
      return quote;
    }
    return {
      'error': '获取行情失败',
      'stockCode': stockCode,
    };
  }
}
