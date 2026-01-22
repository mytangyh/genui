// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Schema for "People Also Ask" card component.
///
/// DSL Example:
/// ```json
/// {
///   "type": "peopleAlsoAskCard",
///   "props": {
///     "title": "大家还在问",
///     "avatarUrl": "https://example.com/avatar.png",
///     "questions": [
///       {"text": "同花顺的基本面是否支持其股价上涨?", "route": "..."},
///       {"text": "同花顺的股价走势是否具备短线交易机会?", "route": "..."},
///       {"text": "同花顺的主力资金流向如何?", "route": "..."}
///     ]
///   }
/// }
/// ```
final _peopleAlsoAskCardSchema = S.object(
  description: '大家还在问卡片，显示相关问题列表',
  properties: {
    'title': S.string(description: '标题，默认为"大家还在问"'),
    'avatarUrl': S.string(description: '头像图片URL'),
    'questions': ListSchema(
      description: '问题列表',
      items: S.object(
        properties: {
          'text': S.string(description: '问题文本'),
          'route': S.string(description: '点击跳转路由'),
        },
        required: ['text'],
      ),
    ),
  },
  required: ['questions'],
);

/// People Also Ask card component.
final peopleAlsoAskCard = CatalogItem(
  name: 'peopleAlsoAskCard',
  dataSchema: _peopleAlsoAskCardSchema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "peopleAlsoAskCard": {
              "title": "大家还在问",
              "questions": [
                {"text": "同花顺的基本面是否支持其股价上涨?"},
                {"text": "同花顺的股价走势是否具备短线交易机会?"},
                {"text": "同花顺的主力资金流向如何?"}
              ]
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final title = data['title'] as String? ?? '大家还在问';
    final avatarUrl = data['avatarUrl'] as String?;
    final questionsRaw = data['questions'] as List<dynamic>? ?? [];

    final questions = questionsRaw.map((q) {
      final map = q as Map<String, dynamic>;
      return _QuestionItem(
        text: map['text'] as String? ?? '',
        route: map['route'] as String?,
      );
    }).toList();

    return _PeopleAlsoAskCard(
      title: title,
      avatarUrl: avatarUrl,
      questions: questions,
      onAction: (name, data) {
        context.dispatchEvent(
          UserActionEvent(
            name: name,
            sourceComponentId: context.id,
            context: data,
          ),
        );
      },
    );
  },
);

class _QuestionItem {
  final String text;
  final String? route;

  _QuestionItem({required this.text, this.route});
}

class _PeopleAlsoAskCard extends StatelessWidget {
  const _PeopleAlsoAskCard({
    required this.title,
    this.avatarUrl,
    required this.questions,
    this.onAction,
  });

  final String title;
  final String? avatarUrl;
  final List<_QuestionItem> questions;
  final void Function(String, Map<String, dynamic>)? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar + Title
          Row(
            children: [
              // Avatar
              // Avatar
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF3A3A45),
                ),
                child: avatarUrl != null
                    ? ClipOval(
                        child: Image.network(
                          avatarUrl!,
                          width: 34,
                          height: 34,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                        ),
                      )
                    : _buildDefaultAvatar(),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'PingFangSC',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.white,
                  height: 26 / 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Questions container
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF232232),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: questions.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                final isLast = index == questions.length - 1;

                return _buildQuestionRow(question, isLast);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF6B8EFF), Color(0xFF9B6BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.person,
        size: 20,
        color: Colors.white,
      ),
    );
  }

  Widget _buildQuestionRow(_QuestionItem question, bool isLast) {
    return InkWell(
      onTap: () {
        if (question.route != null && onAction != null) {
          onAction!('question_tap', {
            'route': question.route,
            'text': question.text,
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(
                    color: Color(0xFF3A3A45),
                    width: 0.5,
                  ),
                ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Q icon (Magnifying glass)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.search,
                size: 18,
                color: Color(0xFFD2D2D3),
              ),
            ),
            const SizedBox(width: 8),
            // Question text
            Expanded(
              child: Text(
                question.text,
                style: const TextStyle(
                  fontFamily: 'PingFangSC',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Color(0xFFD2D2D3),
                  height: 18 / 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
