// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logging/logging.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:simple_chat/main.dart';
import 'package:simple_chat/primitives/app_mode.dart';
import 'package:simple_chat/primitives/climbing/a2ui_components/climbing.dart';

// Import from ../test via relative path since it is not in lib
import '../test/fake_ai_client.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Configure logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  group('Simple Chat Integration Tests', () {
    testWidgets('Text only preserves streamed replies and multi-turn history', (
      tester,
    ) async {
      final client = FakeAiClient()
        ..addResponse('First streamed reply.')
        ..addResponse('Second streamed reply.');
      await tester.pumpWidget(
        MaterialApp(home: ChatScreen(aiClient: client)),
      );
      await _selectMode(tester, AppMode.textOnly);
      await _sendText(tester, 'First turn');
      expect(
        find.textContaining('First streamed reply.', findRichText: true),
        findsOneWidget,
      );
      await _sendText(tester, 'Second turn');
      expect(
        find.textContaining('Second streamed reply.', findRichText: true),
        findsOneWidget,
      );
      expect(client.receivedPrompts, ['First turn', 'Second turn']);
      final Iterable<String> history =
          client.receivedHistories.last.map((message) => message.text);
      expect(history, contains('First turn'));
      expect(history, contains('First streamed reply.'));
      expect(history, contains('Second turn'));
    });

    testWidgets('Basic catalog returns actions and renders the follow-up', (
      tester,
    ) async {
      final String fixture = await rootBundle.loadString(
        'integration_test/samples/sample_2_button.json',
      );
      final client = FakeAiClient()
        ..addResponse('```json\n$fixture\n```')
        ..addResponse('Basic action follow-up.');
      await tester.pumpWidget(
        MaterialApp(home: ChatScreen(aiClient: client)),
      );
      await _selectMode(tester, AppMode.basicCatalog);
      await _sendText(tester, 'Render a button');
      await tester.tap(find.text('Click Me'));
      await _pumpResponse(tester);
      expect(client.receivedPrompts.last, contains('Button Clicked'));
      expect(
        find.textContaining('Basic action follow-up.', findRichText: true),
        findsOneWidget,
      );
      expect(
        client.receivedHistories.last.map((message) => message.text),
        contains(contains('sample_2_button')),
      );
    });

    testWidgets('Custom catalog renders climbing and returns Learn more', (
      tester,
    ) async {
      const fixture = '''
[
  {"version":"v0.9","createSurface":{
    "surfaceId":"compat_climbing",
    "catalogId":"https://a2ui.org/specification/v0_9/basic_catalog.json"}},
  {"version":"v0.9","updateComponents":{
    "surfaceId":"compat_climbing","components":[
      {"id":"root","component":"ClimbingLocation",
       "identifier":"kraft_boulders"}]}}
]
''';
      final client = FakeAiClient()
        ..addResponse('```json\n$fixture\n```')
        ..addResponse('Kraft details follow-up.');
      await tester.pumpWidget(
        MaterialApp(home: ChatScreen(aiClient: client)),
      );
      await _sendText(tester, 'Show Kraft Boulders');
      expect(find.byType(ClimbingLocation), findsOneWidget);
      expect(find.text('Kraft Boulders'), findsOneWidget);
      await tester.ensureVisible(find.text('Learn more'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Learn more'));
      await _pumpResponse(tester);
      expect(client.receivedPrompts.last, contains('learnMoreAboutLocation'));
      expect(client.receivedPrompts.last, contains('kraft_boulders'));
      expect(
        find.textContaining('Kraft details follow-up.', findRichText: true),
        findsOneWidget,
      );
      expect(
        client.receivedHistories.last.map((message) => message.text),
        contains(contains('compat_climbing')),
      );
    });

    testWidgets('render hello world sample', (tester) async {
      await mockNetworkImagesFor(() async {
        await _runTestForSample(
          tester,
          'integration_test/samples/sample_1_hello.json',
          (tester, client) async {
            expect(find.textContaining('Hello, World!'), findsOneWidget);
          },
        );
      });
    });

    testWidgets('render button sample', (tester) async {
      await mockNetworkImagesFor(() async {
        await _runTestForSample(
          tester,
          'integration_test/samples/sample_2_button.json',
          (tester, client) async {
            // Button might be ElevatedButton, TextButton, or FilledButton.
            // Just finding text is safer for integration test unless we care
            // about specific styling.
            expect(find.text('Click Me'), findsOneWidget);

            // Interaction Verification
            await tester.tap(find.text('Click Me'));
            await tester.pump();
            // Button action does not trigger a response if the fake client is
            // empty, but it should send the prompt.
            expect(
              client.receivedPrompts,
              contains(contains('Button Clicked')),
            );
          },
        );
      });
    });

    testWidgets('render form sample', (tester) async {
      await mockNetworkImagesFor(() async {
        await _runTestForSample(
          tester,
          'integration_test/samples/sample_4_form.json',
          (tester, client) async {
            // Debug dump if fails
            expect(find.text('Type'), findsOneWidget);
            expect(find.text('Size'), findsOneWidget);
            expect(find.text('Submit Filters'), findsOneWidget);
          },
        );
      });
    });

    testWidgets('render mixed sample', (tester) async {
      await mockNetworkImagesFor(() async {
        await _runTestForSample(
          tester,
          'integration_test/samples/sample_5_mixed.json',
          (tester, client) async {
            expect(find.text('Do you want to proceed?'), findsOneWidget);
            expect(find.text('Yes, proceed'), findsOneWidget);
          },
        );
      });
    });
  });
}

Future<void> _selectMode(WidgetTester tester, AppMode mode) async {
  await tester.tap(find.byType(DropdownButton<AppMode>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(mode.displayName).last);
  await tester.pumpAndSettle();
}

Future<void> _sendText(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.tap(find.byIcon(Icons.send));
  await _pumpResponse(tester);
}

Future<void> _pumpResponse(WidgetTester tester) async {
  for (int i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _runTestForSample(
  WidgetTester tester,
  String samplePath,
  Future<void> Function(WidgetTester, FakeAiClient) verify,
) async {
  // Bundle samples so the same upstream fixtures are available on devices.
  final String jsonString = await rootBundle.loadString(samplePath);

  // Initialize FakeAiClient
  final fakeAiClient = FakeAiClient();

  // Queue the response
  // SurfaceController expects A2UI messages to be wrapped in markdown code
  // blocks or detectable as structured content. Standard LLM behavior using
  // GenUi is to return ```json ... ``` blocks.
  fakeAiClient.addResponse('Here is the UI:\n```json\n$jsonString\n```');

  await tester.pumpWidget(
    MaterialApp(home: ChatScreen(aiClient: fakeAiClient)),
  );

  // Trigger a message to start the flow
  await tester.enterText(find.byType(TextField), 'Test Trigger');
  await tester.tap(find.byIcon(Icons.send));
  await tester.pump(); // Start processing

  // Wait for response and rendering.
  // The FakeAiClient splits it into chunks with delays.
  // We can't use pumpAndSettle() because some catalog widgets (e.g. Image's
  // loadingBuilder shows a CircularProgressIndicator) have indeterminate
  // animations that is not handled by pumpAndSettle.
  for (int i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  // Run verification
  await verify(tester, fakeAiClient);
}
