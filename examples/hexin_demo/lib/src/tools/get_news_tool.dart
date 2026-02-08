// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../services/market_data_service.dart';

/// 市场新闻 Tool
/// 获取市场/行业/个股相关新闻
class GetNewsTool extends AiTool<Map<String, Object?>> {
  GetNewsTool(this._marketService)
      : super(
          name: 'get_news',
          description: '获取市场新闻和个股公告。可指定股票代码获取个股相关新闻。',
          parameters: S.object(
            properties: {
              'stockCode': S.string(
                description: '可选，股票代码。指定后返回该股票相关新闻',
              ),
              'type': S.string(
                description:
                    '新闻类型: all(全部), macro(宏观), industry(行业), announcement(公告)',
                enumValues: ['all', 'macro', 'industry', 'announcement'],
              ),
            },
          ),
        );

  final MarketDataService _marketService;

  @override
  Future<Map<String, Object?>> invoke(Map<String, Object?> args) async {
    final stockCode = args['stockCode'] as String?;
    final news = await _marketService.getMarketNews(stockCode: stockCode);
    return {
      'news': news,
      'count': news.length,
    };
  }
}
