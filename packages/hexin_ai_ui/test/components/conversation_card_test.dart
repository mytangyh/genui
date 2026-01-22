// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexin_ai_ui/src/components/conversation_card.dart';

void main() {
  testWidgets('ConversationCard renders correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConversationCard(
            onAction: (name, route) {},
            orderRoute: 'client://order',
          ),
        ),
      ),
    );

    expect(find.text('下单'), findsOneWidget);
    expect(find.text('按住说话'), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.byIcon(Icons.keyboard), findsOneWidget);
  });

  testWidgets('ConversationCard triggers actions', (tester) async {
    String? lastAction;
    String? lastRoute;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConversationCard(
            onAction: (name, route) {
              lastAction = name;
              lastRoute = route;
            },
            orderRoute: 'client://order',
            micRoute: 'client://mic',
          ),
        ),
      ),
    );

    // Tap Order
    await tester.tap(find.text('下单'));
    expect(lastAction, 'order_tap');
    expect(lastRoute, 'client://order');

    // Tap Mic
    await tester.tap(find.text('按住说话'));
    expect(lastAction, 'mic_tap');
    expect(lastRoute, 'client://mic');
  });
}
