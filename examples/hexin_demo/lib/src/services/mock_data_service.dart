// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import '../models/portfolio.dart';
import '../models/recommendation.dart';
import '../models/stock.dart';

/// Mock data service for generating simulated financial data.
class MockDataService {
  MockDataService({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Get user's portfolio.
  Future<Portfolio> getPortfolio() async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 300));

    return const Portfolio(
      holdings: [
        StockHolding(
          stockCode: '600519',
          stockName: '贵州茅台',
          shares: 100,
          costPrice: 1680.50,
          currentPrice: 1725.80,
        ),
        StockHolding(
          stockCode: '000858',
          stockName: '五粮液',
          shares: 200,
          costPrice: 185.20,
          currentPrice: 178.90,
        ),
        StockHolding(
          stockCode: '601318',
          stockName: '中国平安',
          shares: 500,
          costPrice: 52.30,
          currentPrice: 55.40,
        ),
        StockHolding(
          stockCode: '600036',
          stockName: '招商银行',
          shares: 300,
          costPrice: 38.50,
          currentPrice: 40.20,
        ),
      ],
      cashBalance: 50000,
    );
  }

  /// Get stock data with historical prices.
  Future<StockData> getStockData(String stockCode, String timeRange) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final Stock stockInfo = _getStockInfo(stockCode);
    final List<PricePoint> priceHistory = _generatePriceHistory(
      stockInfo.currentPrice,
      timeRange,
    );

    return StockData(stock: stockInfo, priceHistory: priceHistory);
  }

  /// Analyze portfolio risk.
  Future<Map<String, dynamic>> analyzeRisk() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final double riskScore = 45 + _random.nextDouble() * 20; // 45-65
    final double volatility = 0.15 + _random.nextDouble() * 0.15; // 15%-30%
    final double diversification = 60 + _random.nextDouble() * 20; // 60-80

    String riskLevel;
    if (riskScore < 40) {
      riskLevel = 'low';
    } else if (riskScore < 60) {
      riskLevel = 'medium';
    } else {
      riskLevel = 'high';
    }

    return {
      'riskLevel': riskLevel,
      'riskScore': riskScore,
      'volatility': volatility,
      'diversification': diversification,
      'suggestions': [
        '建议增加债券类资产配置，降低整体波动性',
        '当前持仓集中在金融和消费板块，可考虑增加科技股',
        '建议设置止损点，控制单只股票最大亏损在10%以内',
      ],
    };
  }

  /// Get investment recommendations.
  Future<List<Recommendation>> getRecommendations({
    String? riskPreference,
    String? investmentGoal,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // Generate recommendations based on risk preference
    final isConservative = riskPreference == 'conservative';

    return [
      const Recommendation(
        action: RecommendationAction.buy,
        stockCode: '601398',
        stockName: '工商银行',
        currentPrice: 5.42,
        targetPrice: 6.20,
        confidence: 75,
        reason: '银行板块估值处于历史低位，分红稳定，适合稳健投资',
        timeHorizon: '6-12个月',
      ),
      if (!isConservative)
        const Recommendation(
          action: RecommendationAction.buy,
          stockCode: '300750',
          stockName: '宁德时代',
          currentPrice: 265.30,
          targetPrice: 320.00,
          confidence: 68,
          reason: '新能源行业景气度高，公司技术领先，长期增长潜力大',
          timeHorizon: '12-18个月',
        ),
      const Recommendation(
        action: RecommendationAction.sell,
        stockCode: '000858',
        stockName: '五粮液',
        currentPrice: 178.90,
        targetPrice: 165.00,
        confidence: 62,
        reason: '白酒板块短期调整压力较大，建议减持部分仓位锁定利润',
        timeHorizon: '1-3个月',
      ),
      const Recommendation(
        action: RecommendationAction.hold,
        stockCode: '600519',
        stockName: '贵州茅台',
        currentPrice: 1725.80,
        confidence: 80,
        reason: '公司基本面良好，长期持有价值高，当前价格合理',
        timeHorizon: '长期持有',
      ),
    ];
  }

  Stock _getStockInfo(String stockCode) {
    final stockData = {
      '600519': ('贵州茅台', 1725.80, 2.7),
      '000858': ('五粮液', 178.90, -3.4),
      '601318': ('中国平安', 55.40, 5.9),
      '600036': ('招商银行', 40.20, 4.4),
      '601398': ('工商银行', 5.42, 1.1),
      '300750': ('宁德时代', 265.30, -2.3),
    };

    final (String, double, double) data =
        stockData[stockCode] ?? ('未知', 0.0, 0.0);

    return Stock(
      stockCode: stockCode,
      stockName: data.$1,
      currentPrice: data.$2,
      changePercent: data.$3,
      volume: 1000000 + _random.nextInt(9000000),
      high: data.$2 * (1 + _random.nextDouble() * 0.03),
      low: data.$2 * (1 - _random.nextDouble() * 0.03),
      open: data.$2 * (1 + (_random.nextDouble() - 0.5) * 0.02),
    );
  }

  List<PricePoint> _generatePriceHistory(double basePrice, String timeRange) {
    final now = DateTime.now();
    final points = <PricePoint>[];

    int numPoints;
    Duration interval;

    switch (timeRange) {
      case '1d':
        numPoints = 240; // 4 hours * 60 minutes
        interval = const Duration(minutes: 1);
      case '5d':
        numPoints = 120; // 5 days * 24 data points
        interval = const Duration(hours: 1);
      case '1m':
        numPoints = 30;
        interval = const Duration(days: 1);
      case '3m':
        numPoints = 60;
        interval = const Duration(days: 1);
      case '1y':
        numPoints = 250; // Trading days
        interval = const Duration(days: 1);
      default:
        numPoints = 240;
        interval = const Duration(minutes: 1);
    }

    double currentPrice = basePrice * 0.98; // Start slightly lower
    for (var i = 0; i < numPoints; i++) {
      final DateTime timestamp = now.subtract(interval * (numPoints - i));

      // Random walk
      final double change = (_random.nextDouble() - 0.5) * basePrice * 0.01;
      currentPrice = (currentPrice + change).clamp(
        basePrice * 0.92,
        basePrice * 1.08,
      );

      points.add(
        PricePoint(
          timestamp: timestamp,
          price: currentPrice,
          volume: 10000 + _random.nextInt(90000),
        ),
      );
    }

    return points;
  }
}
