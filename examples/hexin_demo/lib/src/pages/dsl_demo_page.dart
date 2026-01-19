// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../catalog/catalog.dart';
import '../dsl/dsl.dart';

/// A demo page that shows how DslParser and DslSurface work together.
///
/// This page simulates receiving markdown with embedded DSL blocks
/// from a backend API and rendering them as native Flutter widgets.
class DslDemoPage extends StatefulWidget {
  const DslDemoPage({super.key});

  @override
  State<DslDemoPage> createState() => _DslDemoPageState();
}

class _DslDemoPageState extends State<DslDemoPage> {
  late List<Map<String, dynamic>> _dslBlocks;
  bool _isLoading = true;

  // Simulated markdown response from backend - extended for performance testing
  static const String _mockMarkdownResponse = '''
# 今日市场资讯

欢迎使用智能投顾助手，以下是今日市场要点：

```dsl
{
  "version": "1",
  "children": [
    {
      "type": "ai_message",
      "props": {
        "info": "为您提炼了截至09:28的股市重点",
        "name": "aimi"
      }
    }
  ]
}
```

## 实时行情 (WebView)

```web
{
  "url": "https://m.10jqka.com.cn",
  "height": 250,
  "enableJS": true,
  "loadingText": "加载行情中..."
}
```

## 早间要闻

```dsl
{
  "type": "infoSummaryCard",
  "props": {
    "title": "早间必读",
    "summary": "美国国会众议院以222票支持209票反对通过参议院已通过的联邦政府临时拨款法案。",
    "action": {
      "text": "查看详情",
      "target": "aiapp://news/detail?id=123"
    }
  }
}
```

## 市场快讯

```dsl
{
  "type": "newsFlashList",
  "props": {
    "title": "市场快讯",
    "subtitle": "更新于08:08",
    "items": [
      {
        "content": "国产汽车芯片认证审查技术体系实现突破",
        "tag": "热",
        "tagColor": "#FF4444"
      },
      {
        "content": "红旗涨停潮！AI应用方向集体走高半导体板块",
        "tag": "新",
        "tagColor": "#FF8800"
      },
      {
        "content": "沪指低位震荡半日跌0.56%AI应用方向全面爆发",
        "tag": "",
        "tagColor": ""
      },
      {
        "content": "瑞银：预计明年中国股市将迎来又一丰收年",
        "tag": "",
        "tagColor": ""
      }
    ]
  }
}
```

## 盘前分析

```dsl
{
  "type": "infoSummaryCard",
  "props": {
    "title": "盘前必读",
    "summary": "对盘前解读的资讯内容进行AI汇总解读，并完整展示在这里。点击查看详情跳转到资讯二级页。",
    "action": {
      "text": "查看详情",
      "target": "aiapp://news/premarket"
    }
  }
}
```

## 热门板块

```dsl
{
  "type": "ai_message",
  "props": {
    "info": "为您分析今日热门板块走势",
    "name": "aimi"
  }
}
```

```dsl
{
  "type": "newsFlashList",
  "props": {
    "title": "板块异动",
    "subtitle": "实时更新",
    "items": [
      {
        "content": "半导体板块集体拉升，多只个股涨停",
        "tag": "涨",
        "tagColor": "#FF4444"
      },
      {
        "content": "新能源汽车板块持续走强",
        "tag": "热",
        "tagColor": "#FF8800"
      },
      {
        "content": "医药板块震荡整理，龙头股小幅回调",
        "tag": "",
        "tagColor": ""
      }
    ]
  }
}
```

## 个股推荐

```dsl
{
  "type": "infoSummaryCard",
  "props": {
    "title": "今日推荐",
    "summary": "基于AI智能分析，为您推荐以下潜力股票。请注意投资风险，理性投资。",
    "action": {
      "text": "查看推荐",
      "target": "aiapp://stocks/recommend"
    }
  }
}
```

```dsl
{
  "type": "infoSummaryCard",
  "props": {
    "title": "龙头股分析",
    "summary": "贵州茅台(600519)近期走势强劲，机构持续看好。技术面显示上升趋势明显。",
    "action": {
      "text": "查看详情",
      "target": "aiapp://stocks/600519"
    }
  }
}
```

## K线图 (WebView)

```web
{
  "url": "https://quote.eastmoney.com/center/gridlist.html#hs_a_board",
  "height": 300,
  "enableJS": true,
  "loadingText": "加载K线图..."
}
```

## 财经新闻 (WebView)

```web
{
  "url": "https://m.eastmoney.com",
  "height": 350,
  "enableJS": true,
  "loadingText": "加载财经资讯..."
}
```

## 午后快讯

```dsl
{
  "type": "ai_message",
  "props": {
    "info": "午后市场动态更新",
    "name": "aimi"
  }
}
```

```dsl
{
  "type": "newsFlashList",
  "props": {
    "title": "午后快讯",
    "subtitle": "更新于13:30",
    "items": [
      {
        "content": "A股三大指数午后震荡上行",
        "tag": "新",
        "tagColor": "#44BB44"
      },
      {
        "content": "北向资金午后加速流入",
        "tag": "热",
        "tagColor": "#FF4444"
      },
      {
        "content": "科创板个股普涨，芯片股领涨",
        "tag": "",
        "tagColor": ""
      },
      {
        "content": "港股恒生科技指数涨超2%",
        "tag": "",
        "tagColor": ""
      }
    ]
  }
}
```

## 行业研报

```dsl
{
  "type": "infoSummaryCard",
  "props": {
    "title": "新能源行业研报",
    "summary": "2025年新能源行业展望：锂电池需求持续增长，光伏产业链有望迎来拐点。",
    "action": {
      "text": "阅读研报",
      "target": "aiapp://research/energy"
    }
  }
}
```

```dsl
{
  "type": "infoSummaryCard",
  "props": {
    "title": "人工智能行业研报",
    "summary": "AI大模型商业化加速，算力需求持续增长。建议关注算力基础设施和应用层龙头。",
    "action": {
      "text": "阅读研报",
      "target": "aiapp://research/ai"
    }
  }
}
```

```dsl
{
  "type": "infoSummaryCard",
  "props": {
    "title": "消费电子研报",
    "summary": "MR设备出货量预期上调，产业链相关公司值得重点关注。",
    "action": {
      "text": "阅读研报",
      "target": "aiapp://research/consumer"
    }
  }
}
```

## 晚间复盘

```dsl
{
  "type": "ai_message",
  "props": {
    "info": "今日大盘收盘复盘分析",
    "name": "aimi"
  }
}
```

```dsl
{
  "type": "newsFlashList",
  "props": {
    "title": "收盘总结",
    "subtitle": "15:00 收盘",
    "items": [
      {
        "content": "沪指收涨0.85%，重回3000点上方",
        "tag": "涨",
        "tagColor": "#FF4444"
      },
      {
        "content": "创业板指涨1.23%，连续三日上涨",
        "tag": "涨",
        "tagColor": "#FF4444"
      },
      {
        "content": "两市成交额突破万亿，较昨日放量",
        "tag": "热",
        "tagColor": "#FF8800"
      },
      {
        "content": "北向资金全天净买入超80亿",
        "tag": "新",
        "tagColor": "#44BB44"
      },
      {
        "content": "超3000只个股上涨，赚钱效应明显",
        "tag": "",
        "tagColor": ""
      }
    ]
  }
}
```

## 明日策略

```dsl
{
  "type": "infoSummaryCard",
  "props": {
    "title": "明日操作策略",
    "summary": "今日市场情绪回暖，建议明日可适当加仓科技成长板块，关注半导体、AI应用等方向。",
    "action": {
      "text": "查看策略",
      "target": "aiapp://strategy/tomorrow"
    }
  }
}
```

```dsl
{
  "type": "infoSummaryCard",
  "props": {
    "title": "风险提示",
    "summary": "注意新高股的获利回吐风险，建议设置止盈止损位，控制仓位风险。",
    "action": {
      "text": "风险评估",
      "target": "aiapp://risk/assessment"
    }
  }
}
```

## 更多资讯

```dsl
{
  "type": "ai_message",
  "props": {
    "info": "以下是更多您可能感兴趣的内容",
    "name": "aimi"
  }
}
```

```dsl
{
  "type": "infoSummaryCard",
  "props": {
    "title": "财经日历",
    "summary": "查看本周重要经济数据发布时间和市场事件。",
    "action": {
      "text": "查看日历",
      "target": "aiapp://calendar"
    }
  }
}
```

```dsl
{
  "type": "infoSummaryCard",
  "props": {
    "title": "投资课堂",
    "summary": "学习基础投资知识，提升投资技能，成为更专业的投资者。",
    "action": {
      "text": "开始学习",
      "target": "aiapp://learn"
    }
  }
}
```

```dsl
{
  "type": "infoSummaryCard",
  "props": {
    "title": "模拟炒股",
    "summary": "零风险模拟交易，练习投资技巧，积累实战经验。",
    "action": {
      "text": "开始模拟",
      "target": "aiapp://simulate"
    }
  }
}
```

## 全球市场 (WebView)

```web
{
  "url": "https://www.cls.cn",
  "height": 280,
  "enableJS": true,
  "loadingText": "加载财联社资讯..."
}
```

## 加密货币 (WebView)

```web
{
  "url": "https://www.jinse.cn",
  "height": 320,
  "enableJS": true,
  "loadingText": "加载区块链资讯..."
}
```

## 外汇行情 (WebView)

```web
{
  "url": "https://www.fx678.com",
  "height": 260,
  "enableJS": true,
  "loadingText": "加载外汇数据..."
}
```

以上是今日的市场要点，祝您投资顺利！
''';

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // Parse DSL and Web blocks from markdown
    final dslBlocks = DslParser.extractBlocks(
      _mockMarkdownResponse,
      language: 'dsl',
    );
    final webBlocks = DslParser.extractBlocks(
      _mockMarkdownResponse,
      language: 'web',
    );

    // Convert web blocks to DSL format with type: webview
    final convertedWebBlocks = webBlocks.map((block) {
      return <String, dynamic>{'type': 'webview', 'props': block};
    }).toList();

    // Combine all blocks (in real app, you'd maintain order from markdown)
    final allBlocks = [...dslBlocks, ...convertedWebBlocks];

    // Double the blocks for performance testing
    final doubledBlocks = [...allBlocks, ...allBlocks];

    if (mounted) {
      setState(() {
        _dslBlocks = doubledBlocks;
        _isLoading = false;
      });
    }
  }

  void _handleAction(String actionName, Map<String, dynamic> context) {
    final target = context['target'] as String?;

    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(
        content: Text('Action: $actionName\nTarget: $target'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // In a real app, you would handle the navigation here
    // For example:
    // if (target != null && target.startsWith('aiapp://')) {
    //   final uri = Uri.parse(target);
    //   Navigator.pushNamed(context, uri.path, arguments: uri.queryParameters);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        title: const Text('DSL Demo'),
        backgroundColor: const Color(0xFF1E2A3D),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadContent();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : DslBlockListView(
              blocks: _dslBlocks,
              catalog: FinancialCatalog.getDslCatalog(),
              onAction: _handleAction,
              blockSpacing: 0,
              itemSpacing: 0,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
    );
  }
}

/// A preview widget showing raw markdown and parsed segments.
class DslDebugView extends StatelessWidget {
  const DslDebugView({super.key});

  static const String _sampleMarkdown = '''
Some intro text...

```dsl
{"type": "ai_message", "props": {"info": "Hello World"}}
```

More text here.
''';

  @override
  Widget build(BuildContext context) {
    final segments = DslParser.parseSegments(_sampleMarkdown);

    return Scaffold(
      appBar: AppBar(title: const Text('DSL Debug')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Raw Markdown:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _sampleMarkdown,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Parsed Segments:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...segments.map((segment) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: segment.isText
                    ? Colors.blue.shade50
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: segment.isText
                      ? Colors.blue.shade200
                      : Colors.green.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    segment.isText ? 'TEXT' : 'DSL',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: segment.isText ? Colors.blue : Colors.green,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    segment.isText ? segment.text! : segment.dsl.toString(),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
