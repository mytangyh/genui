// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import '../models/market_breadth_data.dart';

/// Service to handle market data operations.
class MarketDataService {
  final Random _random = Random();

  /// Generates mock market breadth data based on initial values.
  MarketBreadthData generateMockData(MarketBreadthData baseData) {
    // Random fluctuations within ±10%
    final upChange = (baseData.up * 0.1 * (_random.nextDouble() - 0.5)).toInt();
    final downChange =
        (baseData.down * 0.1 * (_random.nextDouble() - 0.5)).toInt();
    final flatChange = (_random.nextInt(20) - 10);

    final newUp = (baseData.up + upChange).clamp(100, 5000);
    final newDown = (baseData.down + downChange).clamp(100, 5000);
    final newFlat = (baseData.flat + flatChange).clamp(0, 500);

    // Limit up/down also fluctuate
    final limitUpChange = _random.nextInt(10) - 5;
    final limitDownChange = _random.nextInt(6) - 3;

    return MarketBreadthData(
      up: newUp,
      down: newDown,
      flat: newFlat,
      limitUp: (baseData.limitUp + limitUpChange).clamp(0, 200),
      limitDown: (baseData.limitDown + limitDownChange).clamp(0, 100),
    );
  }
}
