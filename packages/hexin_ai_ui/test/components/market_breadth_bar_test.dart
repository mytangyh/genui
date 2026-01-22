// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexin_ai_ui/src/components/market_breadth_bar.dart';

void main() {
  testWidgets('MarketBreadthBar renders initial data correctly',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MarketBreadthBar(
            initialUp: 100,
            initialDown: 50,
            initialFlat: 10,
            initialLimitUp: 5,
            initialLimitDown: 2,
          ),
        ),
      ),
    );

    // Check labels
    expect(find.text('涨'), findsOneWidget);
    expect(find.text('跌'), findsOneWidget);
    expect(find.text('平'), findsOneWidget);

    // Check values
    expect(find.text('100'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);

    // Check sub-values (Limit Up/Down)
    expect(find.text('涨停5'), findsOneWidget);
    expect(find.text('跌停2'), findsOneWidget);
  });

  testWidgets('MarketBreadthBar hides Flat section if 0', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MarketBreadthBar(
            initialUp: 100,
            initialDown: 50,
            initialFlat: 0,
          ),
        ),
      ),
    );

    expect(find.text('平'), findsNothing);
  });
}
