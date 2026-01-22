// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Centralized color definitions for hexin_ai_ui.
class AppColors {
  const AppColors._();

  // Backgrounds
  static const Color cardBackground = Color(0xFF191919);

  // Brand/Primary
  static const Color primaryBlue = Color(0xFF2BCCFF);
  static const Color primaryPurple = Color(0xFF9B6BFF);

  // Functional
  static const Color upRed = Color(0xFFFF4D4F); // Unified red
  static const Color downGreen = Color(0xFF00C853);
  static const Color flatGray =
      Color(0xFF666666); // Also used for secondary text

  // Text
  static const Color textWhite = Colors.white;
  static const Color textSecondary = Color(0xFF666666);

  // Gradients
  static const Color gradientRedStart = Color(0xFFFF4444);
  static const Color gradientRedEnd = Color(0xFFFF6B6B);
  static const Color gradientGreenStart = Color(0xFF00C853);
  static const Color gradientGreenEnd = Color(0xFF4CAF50);
}
