// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:hexin_dsl/hexin_dsl.dart';

import '../catalog/catalog.dart';

/// A demo page that shows how DslMarkdownPage renders mixed markdown + DSL.
///
/// This page simulates receiving markdown with embedded DSL blocks
/// from a backend API and rendering them as native Flutter widgets,
/// while also supporting standard markdown formatting.
class DslDemoPage extends StatefulWidget {
  const DslDemoPage({super.key});

  @override
  State<DslDemoPage> createState() => _DslDemoPageState();
}

class _DslDemoPageState extends State<DslDemoPage> {
  bool _isLoading = true;
  List<String> _markdownSections = [];

  // Simulated markdown response from backend - organized by page sections
  static const List<String> _mockMarkdownSections = [
    // Section 1: Market overview with markdown + DSL
    '''# 智能投顾首页

今日市场**开盘走高**，主要指数表现如下：

- 沪指 +0.37%
- 深成指 +0.52%
- 创业板 +0.85%

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
```''',

    // Section 2: Morning news with image
    '''## 早间必读

> 美国国会众议院以222票支持209票反对通过参议院已通过的联邦政府临时拨款法案。

![市场走势](https://zsap.stocke.com.cn/oss-files/YXGL/2025/10/29/6111b7dc10514ea6a2d71ddceb48cfdd.png)

```dsl
{
  "type": "infoSummaryCard",
  "props": {
    "title": "早间必读",
    "summary": "早间必读：美国国会众议院以222票支持209票反对通过参议院已通过的联邦政府临时拨款法案。",
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
      {"text": "沪指低位震荡半日跌0.56%｜AI应用方向全面爆…", "route": "client://news/3"}
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
```''',

    // Section 3: Market statistics
    '''## 大盘统计

截止此时：大盘成交额总计**13214亿**，较上一日此时增+3921亿，预测全天成交**19214亿**。

### 主力资金流向

| 板块 | 净流入 |
|------|--------|
| 上证 | -336.28亿 |
| 深证 | -316.12亿 |
| 创业 | -106.51亿 |
| 科创 | +7.21亿 |

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
      {"route": "client://banner/2", "image_url": "https://via.placeholder.com/400x120/6B8EFF/FFFFFF?text=新手理财课堂"}
    ],
    "height": 120,
    "autoPlay": true,
    "duration": 4000
  }
}
\`\`\`''',

    // Section 4: Native Chart Card Demo
    '''## 原生图表嵌入演示

下面是嵌入的 **Android 原生图表**，支持实时数据刷新和生命周期管理：

\`\`\`dsl
{
  "type": "nativeChartCard",
  "props": {
    "stockCode": "600000",
    "height": 220,
    "refreshInterval": 1000
  }
}
\`\`\`

> 💡 滚动此卡片离开屏幕，刷新次数将暂停；滚回可见区域后恢复刷新。

\`\`\`dsl
{
  "type": "nativeChartCard",
  "props": {
    "stockCode": "000001",
    "height": 220,
    "refreshInterval": 2000
  }
}
\`\`\`''',

    // Section 5: Nested markdownRender demo
    '''## MarkdownRender 嵌套演示

下面演示 DSL 中嵌套 markdownRender 组件：

```dsl
{
  "type": "markdownRender",
  "props": {
    "content": "### 嵌套内容\\n\\n这是一个**嵌套的 markdownRender** 组件\\n\\n- 支持标准 Markdown\\n- 支持列表\\n- 支持*斜体*和**粗体**",
    "backgroundColor": "#1A1F2E"
  }
}
```

```dsl
{
  "type": "ai_buttonList",
  "props": {
    "buttons": [
      {"text": "热门板块", "icon": "analytics", "route": "client://ai/sectors"},
      {"text": "龙头股分析", "icon": "insights", "route": "client://ai/leaders"}
    ]
  }
}
```''',

    // Section 5: WebView demo
    '''## WebView 嵌入演示

使用 ` ``` web ``` ` 代码块嵌入网页：

```web
{
  "url": "https://m.10jqka.com.cn",
  "height": 300,
  "enableJS": true,
  "loadingText": "加载同花顺行情..."
}
```''',

    // Section 6: Summary
    '''## 收盘总结

今日A股三大指数涨跌互现：

1. **沪指** 微涨 +0.12%
2. **深成指** 跌 -0.35%
3. **创业板指** 跌 -0.56%

两市成交额突破**万亿**。

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

---

*数据来源：实时行情*''',
  ];

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _markdownSections = _mockMarkdownSections;
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
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : DslMarkdownPage(
              markdownSections: _markdownSections,
              catalog: FinancialCatalog.getDslCatalog(),
              onAction: _handleAction,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                color:
                    segment.isText ? Colors.blue.shade50 : Colors.green.shade50,
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
