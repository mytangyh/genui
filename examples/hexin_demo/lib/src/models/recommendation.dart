// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Investment recommendation action type.
enum RecommendationAction { buy, sell, hold }

/// Represents an investment recommendation.
class Recommendation {
  const Recommendation({
    required this.action,
    required this.stockCode,
    required this.stockName,
    required this.reason,
    this.targetPrice,
    this.currentPrice,
    this.confidence,
    this.timeHorizon,
  });

  final RecommendationAction action;
  final String stockCode;
  final String stockName;
  final String reason;
  final double? targetPrice;
  final double? currentPrice;
  final double? confidence;
  final String? timeHorizon;

  Map<String, dynamic> toJson() => {
        'action': action.name,
        'stockCode': stockCode,
        'stockName': stockName,
        'reason': reason,
        if (targetPrice != null) 'targetPrice': targetPrice,
        if (currentPrice != null) 'currentPrice': currentPrice,
        if (confidence != null) 'confidence': confidence,
        if (timeHorizon != null) 'timeHorizon': timeHorizon,
      };
}
