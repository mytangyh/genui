// Copyright 2026 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logging/logging.dart';
import 'package:simple_chat/agent/ai_client.dart';
import 'package:simple_chat/main.dart';
import 'package:simple_chat/primitives/app_mode.dart';
import 'package:simple_chat/primitives/climbing/a2ui_components/climbing.dart';

// Manual, credentialed acceptance. This file is excluded from secret-free CI.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  Logger.root.level = Level.INFO;

  testWidgets('real model: Text only streams and remembers previous turns', (
    tester,
  ) async {
    final client = _ObservedClient();
    await tester.pumpWidget(MaterialApp(home: ChatScreen(aiClient: client)));
    await _selectMode(tester, AppMode.textOnly);
    await _send(
      tester,
      client,
      'Remember the verification word ALPHA_3274. Reply only ALPHA_3274.',
    );
    expect(client.outputs.last, contains('ALPHA_3274'));
    expect(
      find.textContaining('ALPHA_3274', findRichText: true),
      findsWidgets,
    );
    await _send(
      tester,
      client,
      'What verification word did I ask you to remember? Reply only the word.',
    );
    expect(client.outputs.last, contains('ALPHA_3274'));
    expect(client.histories.last.map((message) => message.text),
        contains(contains('ALPHA_3274')));
    expect(client.chunkCounts.every((count) => count > 1), isTrue);
    debugPrint(
        'LIVE_TEXT_ONLY passed: requests=2, chunks=${client.chunkCounts}, '
        'lastHistory=${client.histories.last.length}, rendered=true');
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets(
      'real model: Basic catalog renders a button and handles its action',
      (tester) async {
    final client = _ObservedClient();
    await tester.pumpWidget(MaterialApp(home: ChatScreen(aiClient: client)));
    await _selectMode(tester, AppMode.basicCatalog);
    await _send(
      tester,
      client,
      'Create exactly one A2UI Button labelled "Compat Continue" with submit '
      'action "compatContinue". Do not call a climbing tool. When I click the '
      'button, reply with the text BASIC_ACTION_OK.',
    );
    final Finder button = find.text('Compat Continue');
    expect(button, findsOneWidget);
    await tester.ensureVisible(button);
    final int target = client.completedRequests + 1;
    await tester.tap(button);
    await _waitForRequest(tester, client, target);
    expect(client.prompts.last, contains('compatContinue'));
    expect(client.outputs.last, contains('BASIC_ACTION_OK'));
    expect(find.textContaining('BASIC_ACTION_OK', findRichText: true),
        findsWidgets);
    expect(client.histories.last.map((message) => message.text),
        contains(contains('Compat Continue')));
    debugPrint('LIVE_BASIC passed: requests=2, action=compatContinue, '
        'chunks=${client.chunkCounts}, rendered=true');
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets(
      'real model: Custom catalog calls climbing tool and handles Learn more',
      (tester) async {
    int climbingToolCalls = 0;
    final StreamSubscription<LogRecord> subscription =
        Logger.root.onRecord.listen((record) {
      if (record.loggerName == 'SimpleChatTools' &&
          record.message == 'listClimbingLocations executed') {
        climbingToolCalls++;
      }
    });
    addTearDown(subscription.cancel);
    final client = _ObservedClient();
    await tester.pumpWidget(MaterialApp(home: ChatScreen(aiClient: client)));
    await _send(
      tester,
      client,
      'Call listClimbingLocations and show exactly one ClimbingLocation card '
      'for Kraft Boulders (identifier kraft_boulders). '
      'When I click Learn more, '
      'give details about that location and include the text CUSTOM_ACTION_OK.',
    );
    expect(climbingToolCalls, greaterThan(0));
    expect(find.byType(ClimbingLocation), findsOneWidget);
    expect(find.text('Kraft Boulders'), findsOneWidget);
    final Finder button = find.text('Learn more');
    await tester.ensureVisible(button);
    final int target = client.completedRequests + 1;
    await tester.tap(button);
    await _waitForRequest(tester, client, target);
    expect(client.prompts.last, contains('learnMoreAboutLocation'));
    expect(client.prompts.last, contains('kraft_boulders'));
    expect(client.outputs.last, contains('CUSTOM_ACTION_OK'));
    expect(find.textContaining('CUSTOM_ACTION_OK', findRichText: true),
        findsWidgets);
    expect(client.histories.last.map((message) => message.text),
        contains(contains('Kraft Boulders')));
    debugPrint('LIVE_CUSTOM passed: requests=2, toolCalls=$climbingToolCalls, '
        'action=learnMoreAboutLocation, chunks=${client.chunkCounts}, '
        'rendered=true');
  }, timeout: const Timeout(Duration(minutes: 5)));
}

class _ObservedClient implements AiClient {
  final DartanticAiClient _delegate = DartanticAiClient();
  final List<String> prompts = [];
  final List<List<dartantic.ChatMessage>> histories = [];
  final List<String> outputs = [];
  final List<int> chunkCounts = [];
  int completedRequests = 0;
  int failedRequests = 0;

  @override
  Stream<String> sendStream(String prompt,
      {required List<dartantic.ChatMessage> history}) async* {
    prompts.add(prompt);
    histories.add(List.unmodifiable(history));
    final buffer = StringBuffer();
    int chunks = 0;
    try {
      await for (final String chunk
          in _delegate.sendStream(prompt, history: history)) {
        buffer.write(chunk);
        chunks++;
        yield chunk;
      }
    } catch (_) {
      failedRequests++;
      rethrow;
    } finally {
      outputs.add(buffer.toString());
      chunkCounts.add(chunks);
      completedRequests++;
    }
  }

  @override
  void dispose() => _delegate.dispose();
}

Future<void> _selectMode(WidgetTester tester, AppMode mode) async {
  await tester.tap(find.byType(DropdownButton<AppMode>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(mode.displayName).last);
  await tester.pumpAndSettle();
}

Future<void> _send(
    WidgetTester tester, _ObservedClient client, String prompt) async {
  final int target = client.completedRequests + 1;
  await tester.enterText(find.byType(TextField), prompt);
  await tester.tap(find.byIcon(Icons.send));
  await _waitForRequest(tester, client, target);
}

Future<void> _waitForRequest(
    WidgetTester tester, _ObservedClient client, int target) async {
  final DateTime deadline = DateTime.now().add(const Duration(minutes: 2));
  while (
      client.completedRequests < target && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await tester.pump();
  }
  expect(client.completedRequests, target,
      reason: 'Real model request timed out');
  expect(client.failedRequests, 0, reason: 'Real provider request failed');
  await tester.pumpAndSettle();
}
