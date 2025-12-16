// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../services/mock_data_service.dart';

/// Tool for analyzing portfolio risk.
class AnalyzeRiskTool extends AiTool<Map<String, Object?>> {
  AnalyzeRiskTool(this._dataService)
    : super(
        name: 'analyze_risk',
        description: '分析投资组合的风险，包括风险等级、波动率、分散度等指标，并提供优化建议',
        parameters: S.object(properties: {}),
      );

  final MockDataService _dataService;

  @override
  Future<Map<String, Object?>> invoke(Map<String, Object?> args) async {
    final Map<String, dynamic> riskAnalysis = await _dataService.analyzeRisk();
    return riskAnalysis;
  }
}
