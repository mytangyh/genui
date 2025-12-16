// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/genui.dart';

import 'information_card.dart';
import 'risk_assessment_card.dart';
import 'trade_recommendation.dart';
import 'trailhead.dart';

/// Financial catalog for the hexin demo application.
///
/// Note: Limited to core components to avoid Gemini API schema complexity
/// limits. Add more components as needed, but be aware of the total schema
/// size constraint.
class FinancialCatalog {
  /// Returns a catalog with core financial components.
  static Catalog getCatalog() {
    return Catalog([
      // Core financial components (simplified set)
      informationCard,
      riskAssessmentCard,
      tradeRecommendation,
      trailhead,
    ]);
  }
}
