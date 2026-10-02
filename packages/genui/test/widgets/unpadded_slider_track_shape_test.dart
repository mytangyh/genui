// Copyright 2026 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/src/widgets/unpadded_slider_track_shape.dart';

void main() {
  testWidgets('volume track uses the full width and preserves the thumb', (
    tester,
  ) async {
    late SliderThemeData theme;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              theme = SliderTheme.of(context).copyWith(
                overlayShape: SliderComponentShape.noOverlay,
                trackShape: const UnpaddedSliderTrackShape(),
                thumbShape: const RoundSliderThumbShape(),
                trackHeight: 4,
              );
              return Center(
                child: SizedBox(
                  width: 100,
                  height: 60,
                  child: SliderTheme(
                    data: theme,
                    child: Slider(value: 0.5, onChanged: (value) {}),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    final RenderBox box = tester.renderObject(find.byType(Slider));
    final Rect track = theme.trackShape!.getPreferredRect(
      parentBox: box,
      offset: const Offset(10, 20),
      sliderTheme: theme,
      isEnabled: true,
    );
    expect(track.left, 10);
    expect(track.width, 100);
    expect(track.height, 4);
    expect(track.center.dy, 20 + box.size.height / 2);
    expect(
        theme.thumbShape!.getPreferredSize(true, false).width, greaterThan(0));
  });
}
