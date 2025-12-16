// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Schema for market news card component.
final marketNewsSchema = S.object(
  properties: {
    'title': S.string(description: '新闻标题'),
    'summary': S.string(description: '新闻摘要'),
    'source': S.string(description: '新闻来源'),
    'publishTime': S.string(description: '发布时间'),
    'sentiment': S.string(
      description: '情绪',
      enumValues: ['positive', 'neutral', 'negative'],
    ),
    'relatedStocksText': S.string(description: '相关股票代码（逗号分隔）'),
  },
  required: ['title', 'summary'],
);

/// Catalog item for market news card.
final marketNewsCard = CatalogItem(
  name: 'MarketNewsCard',
  dataSchema: marketNewsSchema,
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final String title = data['title'] as String? ?? '';
    final String summary = data['summary'] as String? ?? '';
    final String source = data['source'] as String? ?? '';
    final String publishTime = data['publishTime'] as String? ?? '';
    final String sentiment = data['sentiment'] as String? ?? 'neutral';
    final List<dynamic> relatedStocks = data['relatedStocks'] as List? ?? [];

    Color sentimentColor;
    IconData sentimentIcon;

    switch (sentiment) {
      case 'positive':
        sentimentColor = Colors.red;
        sentimentIcon = Icons.trending_up;
      case 'negative':
        sentimentColor = Colors.green;
        sentimentIcon = Icons.trending_down;
      default:
        sentimentColor = Colors.grey;
        sentimentIcon = Icons.remove;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Could navigate to full article
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with sentiment indicator
              Row(
                children: [
                  Icon(sentimentIcon, color: sentimentColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Summary
              Text(
                summary,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // Footer
              const SizedBox(height: 12),
              Row(
                children: [
                  if (source.isNotEmpty) ...[
                    Icon(
                      Icons.article_outlined,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      source,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  if (publishTime.isNotEmpty && source.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '•',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  if (publishTime.isNotEmpty) ...[
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      publishTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),

              // Related stocks
              if (relatedStocks.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: relatedStocks.map((stock) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        stock.toString(),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  },
);
