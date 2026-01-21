// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/highlights_response.dart';

/// Service for fetching news aggregations from the API.
///
/// Currently using mock data until the API endpoint is accessible.
class HighlightsService {
  HighlightsService({
    this.baseUrl =
        'https://mncg-base-b2b-cloud.0033.com/simulated-stocks-web-saas/ai/info/api/news/aggregations',
    this.useMockData = false,
  });

  /// Base URL for the news aggregations API.
  final String baseUrl;

  /// Whether to use mock data instead of real API calls.
  final bool useMockData;

  /// Fetches news aggregations with optional time range and limit.
  ///
  /// [startTime] - Optional start time filter (epoch milliseconds).
  /// [endTime] - Optional end time filter (epoch milliseconds).
  /// [limit] - Maximum number of results to return (default: 30).
  ///
  /// Returns a [HighlightsResponse] containing the news summaries.
  /// Throws an [Exception] if the request fails or returns an error.
  Future<HighlightsResponse> fetchHighlights({
    int? startTime,
    int? endTime,
    int limit = 30,
  }) async {
    // Use mock data if enabled
    if (useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return HighlightsResponse.fromJson(_mockData);
    }

    try {
      final requestBody = {
        'startTime': startTime,
        'endTime': endTime,
        'limit': limit,
      };

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch highlights: HTTP ${response.statusCode}',
        );
      }

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      final highlightsResponse = HighlightsResponse.fromJson(jsonData);

      // Check API response flag
      if (highlightsResponse.flag != 0) {
        throw Exception('API error: ${highlightsResponse.msg}');
      }

      return highlightsResponse;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to fetch highlights: $e');
    }
  }

  // Mock data for development (first 5 records from the provided data)
  static final Map<String, dynamic> _mockData = {
    "flag": 0,
    "msg": "成功",
    "data": {
      "summaries": [
        {
          "markDown": r'''```dsl
{"simplyDSL":"1","children":[{"type":"targetHeader","props":{"targetName":"上证指数","trend":"flat","targetValue":"4113.62  -0.00%","title":"盘前","timestamp":"1768957957522"}}]}
```
```dsl
{"simplyDSL":"1","children":[{"type":"ai_message","props":{"info":"截至09:12的股市重点","timestamp":"1768957957583"}}]}
```
```dsl
{"simplyDSL":"1","children":[{"type":"ai_event_overview","props":{"event_id":"现货黄金突破4750美元！再创新高"}}]}
```
```dsl
{"simplyDSL":"1","children":[{"type":"ai_buttonList","props":{"buttons":[{"route":"client://ai.route/ai_investment_assistant?question=%E5%B8%AE%E6%88%91%E4%B9%B0%E5%85%A5%E8%88%AA%E5%A4%A9ETF%EF%BC%8C%E8%AF%B7%E5%86%8D%E8%BE%93%E5%85%A5%E5%A7%94%E6%89%98%E4%BB%B7%E6%A0%BC%E5%92%8C%E6%95%B0%E9%87%8F","text":"帮我买入航天ETF"},{"route":"client://ai.route/browser?pi_businesstype=aiweb&url=https%3A%2F%2Fmcash.ctsec.com%2FstockCommunity%2Findex.html%23%2FwxReplyDetail%3FsubjectId%3D69411e3ebbd6966d1544b020","text":"投顾：盘面分析"}]}}]}
```''',
          "updateTime": "1768957957583",
        },
        {
          "markDown": r'''```dsl
{"simplyDSL":"1","children":[{"type":"targetHeader","props":{"targetName":"上证指数","trend":"down","targetValue":"4103.53  -0.25%","title":"盘前","timestamp":"1768958741290"}}]}
```
```dsl
{"simplyDSL":"1","children":[{"type":"ai_message","props":{"info":"截至09:25的股市重点","timestamp":"1768958741462"}}]}
```
```dsl
{"simplyDSL":"1","children":[{"type":"auctionAnomaly","props":{"timestamp":"1768958700014"}}]}
```
```dsl
{"simplyDSL":"1","children":[{"type":"ai_buttonList","props":{"buttons":[{"route":"client://ai.route/browser?pi_businesstype=aiweb&hideNavBar=1&url=https%3A%2F%2Fywbl.sczq.com.cn%3A23456%2Fwt%2Fm%2Fygt%2Fviews%2Faccount%2Findex.html","text":"创业板权限开通"},{"route":"client://ai.route/browser?pi_businesstype=aiweb&hideNavBar=1&url=https%3A%2F%2Fywbl.sczq.com.cn%3A23456%2Fwt%2Fm%2Fygt%2Fviews%2Faccount%2Findex.html","text":"科创板权限开通"}]}}]}
```''',
          "updateTime": "1768958741462",
        },
        {
          "markDown": r'''```dsl
{"simplyDSL":"1","children":[{"type":"targetHeader","props":{"targetName":"上证指数","trend":"up","targetValue":"4128.81  +0.37%","title":"盘中","timestamp":"1768961563057"}}]}
```
```dsl
{"simplyDSL":"1","children":[{"type":"ai_message","props":{"info":"截至10:12的股市重点","timestamp":"1768961563137"}}]}
```
```dsl
{"simplyDSL":"1","children":[{"type":"ai_event_overview","props":{"event_id":"现货黄金突破4800美元！涨势如虹！"}}]}
```
```dsl
{"simplyDSL":"1","children":[{"type":"ai_buttonList","props":{"buttons":[{"route":"client://ai.route/ai_investment_assistant?question=%E5%B8%AE%E6%88%91%E4%B9%B0%E5%85%A5%E8%88%AA%E5%A4%A9ETF%EF%BC%8C%E8%AF%B7%E5%86%8D%E8%BE%93%E5%85%A5%E5%A7%94%E6%89%98%E4%BB%B7%E6%A0%BC%E5%92%8C%E6%95%B0%E9%87%8F","text":"帮我买入航天ETF"},{"route":"client://ai.route/browser?pi_businesstype=aiweb&url=https%3A%2F%2Fmcash.ctsec.com%2FstockCommunity%2Findex.html%23%2FwxReplyDetail%3FsubjectId%3D69411e3ebbd6966d1544b020","text":"投顾：盘面分析"}]}}]}
```''',
          "updateTime": "1768961563138",
        },
        {
          "markDown": r'''```dsl
{"simplyDSL":"1","children":[{"type":"targetHeader","props":{"targetName":"上证指数","trend":"up","targetValue":"4128.46  +0.36%","title":"盘中","timestamp":"1768965527695"}}]}
```
```dsl
{"simplyDSL":"1","children":[{"type":"ai_message","props":{"info":"截至11:18的股市重点","timestamp":"1768965527817"}}]}
```
```dsl
{"simplyDSL":"1","children":[{"type":"newsFlashList","props":{"subtitle":"更新于11:18，更新了2条内容","title":"市场快讯","items":[{"route":"client://ai.route/browser?pi_businesstype=aiweb&url=https%3A%2F%2Fb2b-news.10jqka.com.cn%2FpubInfo%2F%23%2Fnews%2Fdetail%2F674182687%3Ffrom%3Dc%26accessKey%3De1a69891616c39e4","text":"A股指数全线飘红，芯片股爆发，金银股大涨，黄金首次站上4840美元"},{"route":"client://ai.route/browser?pi_businesstype=aiweb&url=https%3A%2F%2Fb2b-news.10jqka.com.cn%2FpubInfo%2F%23%2Fnews%2Fdetail%2F674182215%3Ffrom%3Dc%26accessKey%3De1a69891616c39e4","text":"美方称目标是将台湾半导体供应链产能的40%移美，国台办回应"},{"route":"client://ai.route/browser?pi_businesstype=aiweb&url=https%3A%2F%2Fb2b-news.10jqka.com.cn%2FpubInfo%2F%23%2Fnews%2Fdetail%2F674174804%3Ffrom%3Dc%26accessKey%3De1a69891616c39e4","text":"美国股债汇三杀，纳指跌超2%，芯片股、中概股普跌"},{"route":"client://ai.route/browser?pi_businesstype=aiweb&url=https%3A%2F%2Fb2b-news.10jqka.com.cn%2FpubInfo%2F%23%2Fnews%2Fdetail%2F674172835%3Ffrom%3Dc%26accessKey%3De1a69891616c39e4","text":"突然宣布！清仓美国！丹麦养老基金将退出美国国债投资"}]}}]}
```
```dsl
{"simplyDSL":"1","children":[{"type":"ai_buttonList","props":{"buttons":[{"route":"client://ai.route/browser?pi_businesstype=aiweb&url=https%3A%2F%2Fb2b-api.10jqka.com.cn%2Fb2bgw%2Fresource%2Fh5%2Fprivate%2Fths_b2b%2Flatest%2FStockTrading%2FStockTrading%2Findex.html%23%2Fhome%3Fhxtheme%3Dlight%26akey%3DNjZCQzE5MUEwMDAxJjE3NjQ2NDI5MjAyOTE%3D","text":"今天炒什么"},{"route":"client://ai.route/browser?pi_businesstype=aiweb&url=https%3A%2F%2Fb2b-api.10jqka.com.cn%2Fb2bgw%2Fresource%2Fh5%2Fprivate%2FCTZQ%2Flatest%2FHsgtNew%2FHsgtNew%2Findex.html%23%2F%20","text":"沪深港通"}]}}]}
```''',
          "updateTime": "1768965527818",
        },
        {
          "markDown": r'''```dsl
{"simplyDSL":"1","children":[{"type":"targetHeader","props":{"targetName":"上证指数","trend":"up","targetValue":"4120.10  +0.16%","title":"午间休息","timestamp":"1768966371517"}}]}
```
```dsl
{"simplyDSL":"1","children":[{"type":"ai_message","props":{"info":"截至11:32的股市重点","timestamp":"1768966371581"}}]}
```
```dsl
{"simplyDSL":"1","children":[{"type":"infoSummaryCard","props":{"summary":"A股三大指数早盘集体上涨，截至午盘，沪指涨0.16%，深成指涨0.76%，创业板指涨0.85%，北证50指数涨0.65%，科创50指数涨2.96%，沪深京三市半日成交额16458亿元，较上日缩量2196亿元。全市场超2900只个股上涨。 板块题材上，黄金、有色金属、CPO、半导体、机器人、盐湖提锂、6G概念股涨幅居前；白酒、煤炭、零售、旅游及酒店、电力、机场航运、电网设备板块跌幅居前。盘面上，半导体、AI算力产业链集体爆发，通富微电、长电科技、海光信息创出历史新高，此前马斯克言论催化AI芯片需求。有色资源、黄金股亦大幅上涨，招金黄金、湖南白银等多股封板，特朗普称或对格陵兰岛问题持不同意见国家加征关税，今日国际金价再度大涨并刷新历史新高。此外，机器人、盐湖提锂、化工局部仍有表现。另一方面，白酒、零售等消费板块集体回调，酒鬼酒、水井坊等下跌。电网设备板块未能延续近日强势，和顺电气、双杰电气等股下挫。热门股利欧股份复牌一字跌停，盘中封单额超100亿元。","action":{"route":"client://ai.route/browser?pi_businesstype=aiweb&url=https%3A%2F%2Fnews.10jqka.com.cn%2Fbroker%2Fv2%2Fdetail%2Fq674184053","text":"查看详情"},"title":"A股午评"}}]}
```
```dsl
{"simplyDSL":"1","children":[{"type":"ai_buttonList","props":{"buttons":[{"route":"client://ai.route/browser?pi_businesstype=aiweb&hideNavBar=1&url=https%3A%2F%2Fywbl.sczq.com.cn%3A23456%2Fwt%2Fm%2Fygt%2Fviews%2Faccount%2Findex.html","text":"创业板权限开通"},{"route":"client://ai.route/browser?pi_businesstype=aiweb&url=https%3A%2F%2Fb2b-api.10jqka.com.cn%2Fb2bgw%2Fresource%2Fh5%2Fprivate%2Fths_b2b%2Flatest%2FStockTrading%2FStockTrading%2Findex.html%23%2Fhome%3Fhxtheme%3Dlight%26akey%3DNjZCQzE5MUEwMDAxJjE3NjQ2NDI5MjAyOTE%3D","text":"今天炒什么"}]}}]}
```''',
          "updateTime": "1768966371581",
        },
      ],
      "total": 161,
    },
  };
}
