// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/genui.dart';

import 'trailhead.dart';

/// Financial catalog for the hexin demo application.
class FinancialCatalog {
  /// Returns a catalog with all financial components.
  static Catalog getCatalog() {
    return Catalog([
      // Use original travel_app component to test
      trailhead,
    ]);
  }
}
