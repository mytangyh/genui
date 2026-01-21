// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Represents stock market data.
class Stock {
  const Stock({
    required this.stockCode,
    required this.stockName,
    required this.currentPrice,
    required this.changePercent,
    this.volume,
    this.high,
    this.low,
    this.open,
  });

  final String stockCode;
  final String stockName;
  final double currentPrice;
  final double changePercent;
  final int? volume;
  final double? high;
  final double? low;
  final double? open;

  bool get isRising => changePercent > 0;

  Map<String, dynamic> toJson() => {
        'stockCode': stockCode,
        'stockName': stockName,
        'currentPrice': currentPrice,
        'changePercent': changePercent,
        if (volume != null) 'volume': volume,
        if (high != null) 'high': high,
        if (low != null) 'low': low,
        if (open != null) 'open': open,
      };
}

/// Represents historical price data point.
class PricePoint {
  const PricePoint({required this.timestamp, required this.price, this.volume});

  final DateTime timestamp;
  final double price;
  final int? volume;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'price': price,
        if (volume != null) 'volume': volume,
      };
}

/// Represents stock data with historical prices.
class StockData {
  const StockData({required this.stock, required this.priceHistory});

  final Stock stock;
  final List<PricePoint> priceHistory;

  Map<String, dynamic> toJson() => {
        'stock': stock.toJson(),
        'priceHistory': priceHistory.map((p) => p.toJson()).toList(),
      };
}
