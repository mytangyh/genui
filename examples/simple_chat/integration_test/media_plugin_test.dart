// Copyright 2026 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:video_player/video_player.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native audio loads, plays, seeks and changes volume', (
    tester,
  ) async {
    final player = AudioPlayer();
    addTearDown(player.dispose);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await player.setSource(AssetSource('compat_media/tone.wav'));
    final Duration? duration = await player.getDuration();
    expect(duration, isNotNull);
    expect(duration!.inMilliseconds, greaterThanOrEqualTo(1900));
    await player.setVolume(0.1);
    await player.resume();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect((await player.getCurrentPosition())!.inMilliseconds, greaterThan(0));
    await player.pause();
    await player.seek(const Duration(milliseconds: 1000));
    expect(
      (await player.getCurrentPosition())!.inMilliseconds,
      closeTo(1000, 200),
    );
    await player.setVolume(0);
    expect(player.volume, 0);
    await player.stop();
    expect(player.state, PlayerState.stopped);
  });

  testWidgets('native video decodes, renders, plays and seeks', (tester) async {
    final controller =
        VideoPlayerController.asset('assets/compat_media/blue.mp4');
    addTearDown(controller.dispose);
    await controller.initialize();
    expect(controller.value.isInitialized, isTrue);
    expect(controller.value.hasError, isFalse);
    expect(controller.value.size, const Size(64, 64));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child:
                SizedBox(width: 64, height: 64, child: VideoPlayer(controller)),
          ),
        ),
      ),
    );
    await controller.setVolume(0);
    await controller.play();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.byType(VideoPlayer), findsOneWidget);
    expect(controller.value.position.inMilliseconds, greaterThan(0));
    await controller.pause();
    await controller.seekTo(const Duration(milliseconds: 1000));
    expect(controller.value.position.inMilliseconds, closeTo(1000, 200));
    expect(controller.value.hasError, isFalse);
  });
}
