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

  // Mock data for development - demonstrates standard markdown + DSL blocks
  static final Map<String, dynamic> _mockData = {
    "flag": 0,
    "msg": "成功",
    "data": {
      "summaries": [
        // Test case 1: Standard markdown + DSL blocks + Image
        {
          "markDown": '''# 早盘速递

今日A股**开盘走高**，主要指数全线上涨。以下是重点关注：

- 沪指涨幅 +0.37%
- 深成指涨幅 +0.52%
- 创业板指 +0.85%

![行情走势图](https://zsap.stocke.com.cn/oss-files/YXGL/2025/10/29/6111b7dc10514ea6a2d71ddceb48cfdd.png)

```dsl
{"simplyDSL":"1","children":[{"type":"targetHeader","props":{"targetName":"上证指数","trend":"up","targetValue":"4128.81  +0.37%","title":"盘中","timestamp":"1768961563057"}}]}
```

## 今日要闻

> 现货黄金突破4750美元，再创历史新高！

```dsl
{"simplyDSL":"1","children":[{"type":"ai_message","props":{"info":"截至09:30的股市重点","timestamp":"1768957957583"}}]}
```

### 热门板块

1. **半导体** - 涨幅居前
2. **黄金概念** - 受益金价上涨
3. **AI算力** - 持续活跃

```dsl
{"simplyDSL":"1","children":[{"type":"ai_event_overview","props":{"event_id":"现货黄金突破4750美元！再创新高"}}]}
```

---

*数据来源：实时行情*

```dsl
{"simplyDSL":"1","children":[{"type":"ai_buttonList","props":{"buttons":[{"route":"client://ai.route/ai_investment_assistant","text":"AI投顾"},{"route":"client://ai.route/browser","text":"查看详情"}]}}]}
```''',
          "updateTime": "1768957957583",
        },
        // Test case 2: Nested markdownRender
        {
          "markDown": '''```dsl
{"simplyDSL":"1","children":[{"type":"targetHeader","props":{"targetName":"深证成指","trend":"up","targetValue":"12856.23  +0.52%","title":"盘中","timestamp":"1768958741290"}}]}
```

## 嵌套 MarkdownRender 测试

下面是一个嵌套的 markdownRender 组件：

```dsl
{"type":"markdownRender","props":{"content":"### 嵌套渲染\\n\\n这是一个**嵌套的 markdownRender** 组件\\n\\n- 支持标准 Markdown\\n- 支持列表\\n- 支持*斜体*和**粗体**"}}
```

```dsl
{"simplyDSL":"1","children":[{"type":"ai_buttonList","props":{"buttons":[{"route":"client://test1","text":"测试按钮1"},{"route":"client://test2","text":"测试按钮2"}]}}]}
```''',
          "updateTime": "1768958741462",
        },
        // Test case 3: Pure DSL blocks (original format)
        {
          "markDown": '''```dsl
{"simplyDSL":"1","children":[{"type":"targetHeader","props":{"targetName":"上证指数","trend":"up","targetValue":"4128.81  +0.37%","title":"盘中","timestamp":"1768961563057"}}]}
```
```dsl
{"simplyDSL":"1","children":[{"type":"ai_message","props":{"info":"截至10:12的股市重点","timestamp":"1768961563137"}}]}
```
```dsl
{"simplyDSL":"1","children":[{"type":"ai_event_overview","props":{"event_id":"现货黄金突破4800美元！涨势如虹！"}}]}
```
```dsl
{"simplyDSL":"1","children":[{"type":"ai_buttonList","props":{"buttons":[{"route":"client://ai.route/ai_investment_assistant","text":"帮我买入航天ETF"},{"route":"client://ai.route/browser","text":"投顾：盘面分析"}]}}]}
```''',
          "updateTime": "1768961563138",
        },
        // Test case 4: News flash list
        {
          "markDown": '''```dsl
{"simplyDSL":"1","children":[{"type":"targetHeader","props":{"targetName":"上证指数","trend":"up","targetValue":"4128.46  +0.36%","title":"盘中","timestamp":"1768965527695"}}]}
```
```dsl
{"simplyDSL":"1","children":[{"type":"ai_message","props":{"info":"截至11:18的股市重点","timestamp":"1768965527817"}}]}
```
```dsl
{"simplyDSL":"1","children":[{"type":"newsFlashList","props":{"subtitle":"更新于11:18","title":"市场快讯","items":[{"route":"client://news1","text":"A股指数全线飘红，芯片股爆发"},{"route":"client://news2","text":"国际金价再创新高"}]}}]}
```
```dsl
{"simplyDSL":"1","children":[{"type":"ai_buttonList","props":{"buttons":[{"route":"client://trading","text":"今天炒什么"},{"route":"client://hsgt","text":"沪深港通"}]}}]}
```''',
          "updateTime": "1768965527818",
        },
        // Test case 5: Info summary card
        {
          "markDown": '''```dsl
{"simplyDSL":"1","children":[{"type":"targetHeader","props":{"targetName":"上证指数","trend":"up","targetValue":"4120.10  +0.16%","title":"午间休息","timestamp":"1768966371517"}}]}
```
```dsl
{"simplyDSL":"1","children":[{"type":"ai_message","props":{"info":"截至11:32的股市重点","timestamp":"1768966371581"}}]}
```
```dsl
{"simplyDSL":"1","children":[{"type":"infoSummaryCard","props":{"summary":"A股三大指数早盘集体上涨，截至午盘，沪指涨0.16%，深成指涨0.76%，创业板指涨0.85%。全市场超2900只个股上涨。板块题材上，黄金、有色金属、半导体涨幅居前。","action":{"route":"client://detail","text":"查看详情"},"title":"A股午评"}}]}
```
```dsl
{"simplyDSL":"1","children":[{"type":"ai_buttonList","props":{"buttons":[{"route":"client://permission","text":"创业板权限开通"},{"route":"client://trading","text":"今天炒什么"}]}}]}
```''',
          "updateTime": "1768966371581",
        },
      ],
      "total": 5,
    },
  };
}
