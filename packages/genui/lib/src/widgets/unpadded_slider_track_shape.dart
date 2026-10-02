// Copyright 2026 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Preserves SliderThemeData.padding = EdgeInsets.zero on Flutter 3.27.
///
/// The old track implementation otherwise reserves half the thumb width even
/// when the overlay is disabled. Keep the upstream volume control's full track
/// width, hit positions and rounded painting without changing its thumb.
class UnpaddedSliderTrackShape extends RoundedRectSliderTrackShape {
  const UnpaddedSliderTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double height = sliderTheme.trackHeight!;
    return Rect.fromLTWH(
      offset.dx,
      offset.dy + (parentBox.size.height - height) / 2,
      parentBox.size.width,
      height,
    );
  }
}
