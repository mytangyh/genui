// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../models/recommendation.dart';
import '../services/mock_data_service.dart';

/// Tool for getting investment recommendations.
class GetRecommendationsTool extends AiTool<Map<String, Object?>> {
  GetRecommendationsTool(this._dataService)
    : super(
        name: 'get_recommendations',
        description: '基于用户的风险偏好和投资目标，获取AI生成的个性化交易推荐',
        parameters: S.object(
          properties: {
            'riskPreference': S.string(
              description:
                  '风险偏好: conservative(保守型), moderate(稳健型), aggressive(激进型)',
              enumValues: ['conservative', 'moderate', 'aggressive'],
            ),
            'investmentGoal': S.string(description: '投资目标，例如：稳健增值、高收益、长期投资等'),
          },
        ),
      );

  final MockDataService _dataService;

  @override
  Future<Map<String, Object?>> invoke(Map<String, Object?> args) async {
    final riskPreference = args['riskPreference'] as String?;
    final investmentGoal = args['investmentGoal'] as String?;

    final List<Recommendation> recommendations = await _dataService
        .getRecommendations(
          riskPreference: riskPreference,
          investmentGoal: investmentGoal,
        );

    return {'recommendations': recommendations.map((r) => r.toJson()).toList()};
  }
}
