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

  // Simulated markdown response from backend - organized by page sections
  static const String _mockMarkdownResponse = '''
# 智能投顾首页

```dsl
{
  "type": "targetHeader",
  "props": {
    "timestamp": "08:16",
    "title": "盘前",
    "targetName": "上证指数",
    "targetValue": "3990.49",
    "trend": "up"
  }
}
```

```dsl
{
  "type": "ai_message",
  "props": {
    "info": "为您提炼了截止09:28的股市重点",
    "name": "aimi"
  }
}
```

```dsl
{
  "type": "infoSummaryCard",
  "props": {
    "title": "早间必读",
    "summary": "早间必读：美国国会众议院以222票支持209票反对通过参议院已通过的联邦政府临时对时拨款法案。",
    "action": {
      "text": "查看详情",
      "target": "aiapp://news/morning"
    }
  }
}
```

```dsl
{
  "type": "newsFlashList",
  "props": {
    "title": "市场快讯",
    "subtitle": "更新于08:08，更新了3条内容",
    "items": [
      {"text": "国产汽车芯片认证审查技术体系实现突破", "route": "client://news/1"},
      {"text": "狂飙涨停潮！AI应用方向集体走高半导体板块…", "route": "client://news/2"},
      {"text": "沪指低位震荡半日跌0.56%｜AI应用方向全面爆…", "route": "client://news/3"},
      {"text": "瑞银：预计明年中国股市将迎来又一个丰…", "route": "client://news/4"}
    ]
  }
}
```

```dsl
{
  "type": "ai_buttonList",
  "props": {
    "buttons": [
      {"text": "今天炒什么", "icon": "whatshot", "route": "client://ai/today"},
      {"text": "昨日涨停表现", "icon": "trending_up", "route": "client://ai/yesterday"}
    ]
  }
}
```

```dsl
{
  "type": "targetHeader",
  "props": {
    "timestamp": "09:18",
    "title": "盘前",
    "targetName": "上证指数",
    "targetValue": "3990.49 -1.04%",
    "trend": "down"
  }
}
```

```dsl
{
  "type": "ai_message",
  "props": {
    "info": "为您提炼了截止09:28的股市重点",
    "detail": "对盘前解读的资讯内容进行AI汇总解读，并完整展示在这里。点击查看详情链接跳转到资讯二级页。",
    "name": "aimi",
    "expandable": true
  }
}
```

```dsl
{
  "type": "sectionHeader",
  "props": {
    "title": "盘前必读",
    "action": {
      "type": "image",
      "text": "AI 深度解读",
      "route": "client://ai/premarket"
    }
  }
}
```

```dsl
{
  "type": "infoSummaryCard",
  "props": {
    "title": "市场概览",
    "summary": "对盘前解读的资讯内容进行AI汇总解读，并完整展示在这里。点击查看详情跳转到资讯二级页。",
    "action": {
      "text": "查看详情",
      "target": "aiapp://market/overview"
    }
  }
}
```

```dsl
{
  "type": "sectionHeader",
  "props": {
    "title": "竞价异动",
    "action": {
      "type": "text",
      "text": "查看更多",
      "route": "client://market/auction"
    }
  }
}
```

```dsl
{
  "type": "marketBreadthBar",
  "props": {
    "up": 2272,
    "down": 1499,
    "flat": 13,
    "limitUp": 62,
    "limitDown": 13
  }
}
```

```dsl
{
  "type": "banner_carousel",
  "props": {
    "items": [
      {"route": "client://banner/1", "image_url": "https://via.placeholder.com/400x120/FF8C00/FFFFFF?text=AI+智能选股"},
      {"route": "client://banner/2", "image_url": "https://via.placeholder.com/400x120/6B8EFF/FFFFFF?text=新手理财课堂"},
      {"route": "client://banner/3", "image_url": "https://via.placeholder.com/400x120/B06BFF/FFFFFF?text=热门板块分析"}
    ],
    "height": 120,
    "autoPlay": true,
    "duration": 4000
  }
}
```

```dsl
{
  "type": "sectionHeader",
  "props": {
    "title": "大盘统计",
    "action": {
      "type": "image",
      "text": "AI 深度解读",
      "route": "client://ai/market"
    }
  }
}
```

```dsl
{
  "type": "markdownRender",
  "props": {
    "content": "截止此时：大盘成交额总计**13214亿**，较上一日此时增+3921亿，预测全天成交**19214亿**，预测全天场增+391亿。大盘主力净流入-657.51亿，其中上证主力净流入-336.28亿，深证主力净流入-316.12亿，创业板主力净流入-106.51亿，科创板主力进入+7.21亿。"
  }
}
```

```dsl
{
  "type": "marketBreadthBar",
  "props": {
    "up": 2272,
    "down": 1499,
    "flat": 13,
    "limitUp": 62,
    "limitDown": 13
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
      {"text": "A股三大指数午后震荡上行", "route": "client://news/5"},
      {"text": "北向资金午后加速流入", "route": "client://news/6"},
      {"text": "科创板个股普涨，芯片股领涨", "route": "client://news/7"},
      {"text": "港股恒生科技指数涨超2%", "route": "client://news/8"}
    ]
  }
}
```

```dsl
{
  "type": "ai_buttonList",
  "props": {
    "buttons": [
      {"text": "热门板块", "icon": "analytics", "route": "client://ai/sectors"},
      {"text": "龙头股分析", "icon": "insights", "route": "client://ai/leaders"},
      {"text": "风险提示", "icon": "recommend", "route": "client://ai/risk"}
    ]
  }
}
```

```dsl
{
  "type": "infoSummaryCard",
  "props": {
    "title": "收盘总结",
    "summary": "今日A股三大指数涨跌互现，沪指微涨0.12%，深成指跌0.35%，创业板指跌0.56%。两市成交额突破万亿。",
    "action": {
      "text": "查看完整报告",
      "target": "aiapp://report/daily"
    }
  }
}
```

```dsl
{
  "type": "sectionHeader",
  "props": {
    "title": "MarkdownRender 组合演示",
    "action": {
      "type": "text",
      "text": "智能容器",
      "route": "client://demo/markdown"
    }
  }
}
```

```dsl
{
  "type": "markdownRender",
  "props": {
    "content": "## 大盘统计\n\n截止此时：大盘成交额总计**13214亿**，较上一日此时增+3921亿，预测全天成交**19214亿**。\n\n大盘主力净流入-657.51亿，其中上证主力净流入-336.28亿，深证主力净流入-316.12亿，创业板主力净流入-106.51亿，科创板主力进入+7.21亿。",
    "backgroundColor": "#1A1F2E"
  }
}
```

```dsl
{
  "type": "sectionHeader",
  "props": {
    "title": "WebView 嵌入演示",
    "action": {
      "type": "text",
      "text": "原生性能",
      "route": "client://demo/webview"
    }
  }
}
```

```web
{
  "url": "https://m.10jqka.com.cn",
  "height": 300,
  "enableJS": true,
  "loadingText": "加载同花顺行情..."
}
```

```web
{
  "url": "https://m.eastmoney.com",
  "height": 300,
  "enableJS": true,
  "loadingText": "加载东方财富..."
}
```

```dsl
{
  "type": "sectionHeader",
  "props": {
    "title": "实时数据演示",
    "action": {
      "type": "text",
      "text": "Polling 2s",
      "route": "client://demo/realtime"
    }
  }
}
```

```dsl
{
  "type": "marketBreadthBar",
  "props": {
    "up": 2272,
    "down": 1499,
    "flat": 13,
    "limitUp": 62,
    "limitDown": 13,
    "dataSource": {
      "type": "polling",
      "interval": 2000
    }
  }
}
```
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

    // Combine all blocks
    final allBlocks = [...dslBlocks, ...convertedWebBlocks];

    if (mounted) {
      setState(() {
        _dslBlocks = allBlocks;
        _isLoading = false;
      });
    }
  }

  void _handleAction(String actionName, Map<String, dynamic> context) {
    final target = context['target'] as String?;
    final route = context['route'] as String?;

    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(
        content: Text('Action: $actionName\nTarget: ${target ?? route}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
