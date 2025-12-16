// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../models/stock.dart';
import '../services/mock_data_service.dart';

/// Tool for getting stock data with historical prices.
class GetStockDataTool extends AiTool<Map<String, Object?>> {
  GetStockDataTool(this._dataService)
    : super(
        name: 'get_stock_data',
        description: '获取指定股票的实时数据和历史走势，包括价格、涨跌幅、成交量等',
        parameters: S.object(
          properties: {
            'stockCode': S.string(description: '股票代码，如 600519'),
            'timeRange': S.string(
              description: '时间范围: 1d(1天), 5d(5天), 1m(1月), 3m(3月), 1y(1年)',
              enumValues: ['1d', '5d', '1m', '3m', '1y'],
            ),
          },
          required: ['stockCode'],
        ),
      );

  final MockDataService _dataService;

  @override
  Future<Map<String, Object?>> invoke(Map<String, Object?> args) async {
    final stockCode = args['stockCode'] as String;
    final String timeRange = args['timeRange'] as String? ?? '1d';

    final StockData stockData = await _dataService.getStockData(
      stockCode,
      timeRange,
    );
    return stockData.toJson();
  }
}
