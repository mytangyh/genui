// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Represents a stock holding in the portfolio.
class StockHolding {
  const StockHolding({
    required this.stockCode,
    required this.stockName,
    required this.shares,
    required this.costPrice,
    required this.currentPrice,
  });

  final String stockCode;
  final String stockName;
  final int shares;
  final double costPrice;
  final double currentPrice;

  double get totalCost => shares * costPrice;
  double get currentValue => shares * currentPrice;
  double get profit => currentValue - totalCost;
  double get profitPercent => totalCost == 0 ? 0 : (profit / totalCost) * 100;

  Map<String, dynamic> toJson() => {
    'stockCode': stockCode,
    'stockName': stockName,
    'shares': shares,
    'costPrice': costPrice,
    'currentPrice': currentPrice,
    'profit': profit,
    'profitPercent': profitPercent,
  };
}

/// Represents a user's investment portfolio.
class Portfolio {
  const Portfolio({required this.holdings, this.cashBalance = 0});

  final List<StockHolding> holdings;
  final double cashBalance;

  double get totalStockValue =>
      holdings.fold(0, (sum, holding) => sum + holding.currentValue);
  double get totalValue => totalStockValue + cashBalance;
  double get totalCost =>
      holdings.fold(0, (sum, holding) => sum + holding.totalCost);
  double get totalProfit => totalValue - totalCost - cashBalance;
  double get profitPercent =>
      totalCost == 0 ? 0 : (totalProfit / totalCost) * 100;

  Map<String, dynamic> toJson() => {
    'totalValue': totalValue,
    'totalProfit': totalProfit,
    'profitPercent': profitPercent,
    'cashBalance': cashBalance,
    'holdings': holdings.map((h) => h.toJson()).toList(),
  };
}
