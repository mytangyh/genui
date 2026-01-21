// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../models/portfolio.dart';
import '../services/mock_data_service.dart';

/// Tool for getting user's investment portfolio.
class GetPortfolioTool extends AiTool<Map<String, Object?>> {
  GetPortfolioTool(this._dataService)
      : super(
          name: 'get_portfolio',
          description: '获取用户的投资组合信息，包括持仓股票、总资产、盈亏等数据',
          parameters: S.object(properties: {}),
        );

  final MockDataService _dataService;

  @override
  Future<Map<String, Object?>> invoke(Map<String, Object?> args) async {
    final Portfolio portfolio = await _dataService.getPortfolio();
    return portfolio.toJson();
  }
}
