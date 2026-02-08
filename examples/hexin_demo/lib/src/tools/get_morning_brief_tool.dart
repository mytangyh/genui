// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../services/market_data_service.dart';

/// 盘前晨会要点 Tool
/// 获取今日大盘概况、重点新闻、板块关注、持仓提醒
class GetMorningBriefTool extends AiTool<Map<String, Object?>> {
  GetMorningBriefTool(this._marketService)
      : super(
          name: 'get_morning_brief',
          description: '获取今日盘前晨会要点，包括：大盘指数、重点新闻、板块关注、持仓股票提醒。适用于盘前场景。',
          parameters: S.object(properties: {}),
        );

  final MarketDataService _marketService;

  @override
  Future<Map<String, Object?>> invoke(Map<String, Object?> args) async {
    return await _marketService.getMorningBrief();
  }
}
