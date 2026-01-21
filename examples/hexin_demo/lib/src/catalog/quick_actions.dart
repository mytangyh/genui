// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Schema for quick actions component - interactive buttons that trigger AI.
final _quickActionsSchema = S.object(
  properties: {
    'title': A2uiSchemas.stringReference(description: '标题'),
    'actions': S.list(
      description: '操作按钮列表',
      items: S.object(
        properties: {
          'label': A2uiSchemas.stringReference(description: '按钮文字'),
          'icon': S.string(description: '图标名: trending_up, search, info'),
        },
        required: ['label'],
      ),
    ),
    'action': A2uiSchemas.action(
      description: '点击按钮时触发的操作，选中的label会作为context传递',
    ),
  },
  required: ['actions', 'action'],
);

extension type _QuickActionsData.fromMap(Map<String, Object?> _json) {
  JsonMap? get title => _json['title'] as JsonMap?;
  List<JsonMap> get actions => (_json['actions'] as List).cast<JsonMap>();
  JsonMap get action => _json['action'] as JsonMap;
}

/// A component with interactive action buttons that trigger AI responses.
///
/// When user taps a button, it sends the selected action to the AI,
/// which can then generate new UI in response.
final quickActions = CatalogItem(
  name: 'QuickActions',
  dataSchema: _quickActionsSchema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "QuickActions": {
              "title": {"literalString": "您想了解什么？"},
              "actions": [
                {"label": {"literalString": "查看持仓"}, "icon": "account_balance_wallet"},
                {"label": {"literalString": "分析风险"}, "icon": "trending_up"},
                {"label": {"literalString": "投资建议"}, "icon": "lightbulb"}
              ],
              "action": {"name": "quick_action_selected"}
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (itemContext) {
    final data = _QuickActionsData.fromMap(
      itemContext.data as Map<String, Object?>,
    );
    return _QuickActions(
      titleRef: data.title,
      actions: data.actions,
      actionDef: data.action,
      widgetId: itemContext.id,
      dispatchEvent: itemContext.dispatchEvent,
      dataContext: itemContext.dataContext,
    );
  },
);

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.titleRef,
    required this.actions,
    required this.actionDef,
    required this.widgetId,
    required this.dispatchEvent,
    required this.dataContext,
  });

  final JsonMap? titleRef;
  final List<JsonMap> actions;
  final JsonMap actionDef;
  final String widgetId;
  final DispatchEventCallback dispatchEvent;
  final DataContext dataContext;

  IconData _getIcon(String? iconName) {
    return switch (iconName) {
      'trending_up' => Icons.trending_up,
      'trending_down' => Icons.trending_down,
      'search' => Icons.search,
      'info' => Icons.info_outline,
      'lightbulb' => Icons.lightbulb_outline,
      'account_balance_wallet' => Icons.account_balance_wallet,
      'analytics' => Icons.analytics,
      'assessment' => Icons.assessment,
      'pie_chart' => Icons.pie_chart,
      _ => Icons.touch_app,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (titleRef != null)
              ValueListenableBuilder<String?>(
                valueListenable: dataContext.subscribeToString(titleRef),
                builder: (context, title, _) {
                  if (title == null || title.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions.map((actionItem) {
                final labelRef = actionItem['label'] as JsonMap?;
                final iconName = actionItem['icon'] as String?;

                return ValueListenableBuilder<String?>(
                  valueListenable: dataContext.subscribeToString(labelRef),
                  builder: (context, label, _) {
                    if (label == null) return const SizedBox.shrink();

                    return ElevatedButton.icon(
                      icon: Icon(_getIcon(iconName), size: 18),
                      label: Text(label),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        final name = actionDef['name'] as String;
                        final List<Object?> contextDef =
                            (actionDef['context'] as List<Object?>?) ??
                                <Object?>[];
                        final JsonMap resolvedContext = resolveContext(
                          dataContext,
                          contextDef,
                        );
                        // Pass the selected action label to AI
                        resolvedContext['selectedAction'] = label;
                        dispatchEvent(
                          UserActionEvent(
                            name: name,
                            sourceComponentId: widgetId,
                            context: resolvedContext,
                          ),
                        );
                      },
                    );
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
