// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Data model for market breadth statistics.
class MarketBreadthData {
  const MarketBreadthData({
    required this.up,
    required this.down,
    this.flat = 0,
    this.limitUp = 0,
    this.limitDown = 0,
  });

  /// Number of stocks went up.
  final int up;

  /// Number of stocks went down.
  final int down;

  /// Number of flat stocks.
  final int flat;

  /// Number of stocks hit limit up.
  final int limitUp;

  /// Number of stocks hit limit down.
  final int limitDown;
}
