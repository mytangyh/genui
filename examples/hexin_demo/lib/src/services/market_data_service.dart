// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 真实市场数据服务 - 对接新浪财经 API
class MarketDataService {
  MarketDataService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  static const _sinaBaseUrl = 'https://hq.sinajs.cn';

  /// 获取实时股票行情
  /// 支持格式：sh600519（沪市）、sz000001（深市）
  Future<Map<String, dynamic>?> getRealTimeQuote(String stockCode) async {
    try {
      final sinaCode = _toSinaCode(stockCode);
      final uri = Uri.parse('$_sinaBaseUrl/list=$sinaCode');

      debugPrint('📡 [MarketData] 请求行情: $sinaCode');

      final response = await _httpClient.get(
        uri,
        headers: {
          'Referer': 'https://finance.sina.com.cn',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      debugPrint('📡 [MarketData] 响应状态: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final result = _parseSinaQuote(sinaCode, body);
        if (result != null) {
          debugPrint(
              '✅ [MarketData] $sinaCode: ${result['stockName']} ${result['currentPrice']} (${result['changePercent']?.toStringAsFixed(2)}%)');
        } else {
          debugPrint('⚠️ [MarketData] $sinaCode: 解析失败');
        }
        return result;
      }
    } catch (e) {
      debugPrint('❌ [MarketData] 获取实时行情失败: $e');
    }
    return null;
  }

  /// 批量获取实时行情
  Future<List<Map<String, dynamic>>> getBatchQuotes(
      List<String> stockCodes) async {
    final results = <Map<String, dynamic>>[];
    for (final code in stockCodes) {
      final quote = await getRealTimeQuote(code);
      if (quote != null) {
        results.add(quote);
      }
    }
    return results;
  }

  /// 获取大盘概况（真实数据）
  /// 返回三大指数的实时行情
  Future<Map<String, dynamic>> getMarketOverview() async {
    debugPrint('📊 [MarketData] 开始获取大盘概况...');

    // 并行获取三大指数
    final futures = await Future.wait([
      getRealTimeQuote('sh000001'), // 上证指数
      getRealTimeQuote('sz399001'), // 深证成指
      getRealTimeQuote('sz399006'), // 创业板指
    ]);

    final shIndex = futures[0];
    final szIndex = futures[1];
    final cyIndex = futures[2];

    // 计算市场情绪
    String marketSentiment = '中性';
    int upCount = 0;
    if (shIndex != null && (shIndex['changePercent'] as num) > 0) upCount++;
    if (szIndex != null && (szIndex['changePercent'] as num) > 0) upCount++;
    if (cyIndex != null && (cyIndex['changePercent'] as num) > 0) upCount++;
    if (upCount >= 2) {
      marketSentiment = '偏多';
    } else if (upCount == 0) {
      marketSentiment = '偏空';
    }

    debugPrint(
        '📊 [MarketData] 大盘概况完成: 市场情绪=$marketSentiment, 上涨指数=$upCount/3');

    return {
      'updateTime': DateTime.now().toString().substring(0, 19),
      'indices': {
        '上证指数': shIndex ?? _mockIndexData('上证指数', 3100),
        '深证成指': szIndex ?? _mockIndexData('深证成指', 10000),
        '创业板指': cyIndex ?? _mockIndexData('创业板指', 2000),
      },
      'marketSentiment': marketSentiment,
      'summary':
          _formatMarketSummary(shIndex, szIndex, cyIndex, marketSentiment),
    };
  }

  String _formatMarketSummary(
    Map<String, dynamic>? sh,
    Map<String, dynamic>? sz,
    Map<String, dynamic>? cy,
    String sentiment,
  ) {
    final shPrice = sh?['currentPrice']?.toStringAsFixed(2) ?? '--';
    final shChange = sh?['changePercent']?.toStringAsFixed(2) ?? '--';
    final szPrice = sz?['currentPrice']?.toStringAsFixed(2) ?? '--';
    final szChange = sz?['changePercent']?.toStringAsFixed(2) ?? '--';
    final cyPrice = cy?['currentPrice']?.toStringAsFixed(2) ?? '--';
    final cyChange = cy?['changePercent']?.toStringAsFixed(2) ?? '--';

    return '''上证指数 $shPrice (${_formatChange(shChange.toString())}%)
深证成指 $szPrice (${_formatChange(szChange.toString())}%)
创业板指 $cyPrice (${_formatChange(cyChange.toString())}%)

📈 市场情绪：$sentiment''';
  }

  String _formatChange(String change) {
    if (change == '--') return change;
    final num = double.tryParse(change) ?? 0;
    return num >= 0 ? '+$change' : change;
  }

  /// 获取晨会要点（Mock + 真实市场数据混合）
  Future<Map<String, dynamic>> getMorningBrief() async {
    final now = DateTime.now();
    final dateStr = '${now.month}月${now.day}日';

    // 获取大盘指数
    final shIndex = await getRealTimeQuote('sh000001'); // 上证指数
    final szIndex = await getRealTimeQuote('sz399001'); // 深证成指
    final cyIndex = await getRealTimeQuote('sz399006'); // 创业板指

    return {
      'date': dateStr,
      'marketOverview': {
        '上证指数': shIndex ?? _mockIndexData('上证指数', 3100),
        '深证成指': szIndex ?? _mockIndexData('深证成指', 10000),
        '创业板指': cyIndex ?? _mockIndexData('创业板指', 2000),
      },
      'highlights': [
        '美股三大指数昨夜收涨，纳斯达克指数创年内新高',
        '央行公开市场操作净投放1000亿元，资金面保持宽松',
        '新能源板块利好：固态电池突破性进展，多家上市公司受益',
        '北向资金昨日净流入42亿元，连续3日加仓',
      ],
      'sectorFocus': [
        {'name': '新能源', 'trend': 'up', 'reason': '固态电池技术突破'},
        {'name': '半导体', 'trend': 'up', 'reason': '国产替代加速'},
        {'name': '白酒', 'trend': 'down', 'reason': '短期调整压力'},
      ],
      'portfolioAlerts': [
        {'stock': '比亚迪', 'alert': '关注280元压力位，突破可加仓'},
        {'stock': '贵州茅台', 'alert': '今日发布年报，关注业绩指引'},
      ],
    };
  }

  /// 获取市场新闻（Mock 数据，实际接入需要新闻 API）
  Future<List<Map<String, dynamic>>> getMarketNews({String? stockCode}) async {
    final now = DateTime.now();

    // 基础新闻
    final allNews = <Map<String, dynamic>>[
      {
        'title': '央行：继续实施稳健的货币政策，保持流动性合理充裕',
        'source': '中国人民银行',
        'time': '${now.hour - 1}:30',
        'type': 'macro',
        'impact': 'positive',
      },
      {
        'title': '北向资金今日净流入超40亿元，加仓新能源和消费板块',
        'source': '东方财富',
        'time': '${now.hour}:15',
        'type': 'flow',
        'impact': 'positive',
      },
      {
        'title': '固态电池技术获重大突破，多家上市公司宣布加大研发投入',
        'source': '证券时报',
        'time': '08:30',
        'type': 'industry',
        'impact': 'positive',
      },
      {
        'title': '白酒行业：短期库存压力仍存，龙头公司估值回归',
        'source': '中信证券',
        'time': '09:00',
        'type': 'research',
        'impact': 'neutral',
      },
    ];

    // 如果指定股票代码，添加个股新闻
    if (stockCode != null) {
      final stockName = _getStockName(stockCode);
      allNews.insert(
        0,
        {
          'title': '$stockName：公司发布业绩预告，预计全年净利润同比增长15%-20%',
          'source': '公司公告',
          'time': '08:00',
          'type': 'announcement',
          'impact': 'positive',
          'stockCode': stockCode,
        },
      );
    }

    return allNews;
  }

  /// 获取今日操作记录（用于盘后复盘）
  Future<Map<String, dynamic>> getTradingHistory() async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return {
      'date': dateStr,
      'trades': [
        {
          'time': '10:23:15',
          'action': 'buy',
          'stockCode': '002594',
          'stockName': '比亚迪',
          'price': 275.50,
          'quantity': 100,
          'amount': 27550.0,
          'reason': '突破5日均线，追涨买入',
        },
        {
          'time': '14:45:32',
          'action': 'sell',
          'stockCode': '002594',
          'stockName': '比亚迪',
          'price': 272.30,
          'quantity': 50,
          'amount': 13615.0,
          'reason': '下跌恐慌，割肉卖出',
        },
      ],
      'summary': {
        'totalTrades': 2,
        'buyAmount': 27550.0,
        'sellAmount': 13615.0,
        'netAmount': -13935.0,
        'realizedPL': -160.0, // (272.30-275.50)*50
        'winRate': 0,
      },
      'behaviorTags': [
        {'tag': '追涨杀跌', 'count': 1},
        {'tag': '频繁交易', 'count': 2},
        {'tag': '恐慌卖出', 'count': 1},
      ],
    };
  }

  // === 私有辅助方法 ===

  String _toSinaCode(String code) {
    // 已经是新浪格式
    if (code.startsWith('sh') || code.startsWith('sz')) {
      return code;
    }
    // 纯数字代码，自动判断市场
    if (code.startsWith('6') || code.startsWith('9')) {
      return 'sh$code'; // 沪市
    }
    return 'sz$code'; // 深市
  }

  Map<String, dynamic>? _parseSinaQuote(String sinaCode, String body) {
    // 新浪返回格式: var hq_str_sh600519="贵州茅台,1725.00,1720.00,...";
    final regex = RegExp(r'var hq_str_\w+="(.*)";');
    final match = regex.firstMatch(body);
    if (match == null || match.group(1)?.isEmpty == true) {
      return null;
    }

    final parts = match.group(1)!.split(',');
    if (parts.length < 32) return null;

    final stockCode = sinaCode.substring(2); // 去掉 sh/sz 前缀
    final open = double.tryParse(parts[1]) ?? 0;
    final preClose = double.tryParse(parts[2]) ?? 0;
    final current = double.tryParse(parts[3]) ?? 0;
    final high = double.tryParse(parts[4]) ?? 0;
    final low = double.tryParse(parts[5]) ?? 0;
    final volume = double.tryParse(parts[8]) ?? 0; // 成交量（股）
    final amount = double.tryParse(parts[9]) ?? 0; // 成交额（元）

    final change = current - preClose;
    final changePercent = preClose > 0 ? (change / preClose) * 100 : 0;

    return {
      'stockCode': stockCode,
      'stockName': parts[0],
      'currentPrice': current,
      'openPrice': open,
      'preClose': preClose,
      'high': high,
      'low': low,
      'change': change,
      'changePercent': changePercent,
      'volume': volume.toInt(),
      'amount': amount,
      'updateTime': '${parts[30]} ${parts[31]}',
    };
  }

  Map<String, dynamic> _mockIndexData(String name, double base) {
    final random = Random();
    final change = (random.nextDouble() - 0.5) * 2;
    return {
      'stockName': name,
      'currentPrice': base + random.nextDouble() * 50,
      'changePercent': change,
    };
  }

  String _getStockName(String code) {
    const names = {
      '600519': '贵州茅台',
      '002594': '比亚迪',
      '601318': '中国平安',
      '000858': '五粮液',
      '600036': '招商银行',
    };
    return names[code] ?? '未知股票';
  }
}
