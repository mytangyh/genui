// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/genui.dart';

import 'package:hexin_ai_ui/hexin_ai_ui.dart';

/// Financial catalog for the hexin demo application.
class FinancialCatalog {
  /// Returns the full catalog for DSL parsing (all components).
  static Catalog getDslCatalog() {
    return Catalog([
      ...AiUiCatalog.getAllItems(),
    ]);
  }

  /// Alias for getDslCatalog for backward compatibility.
  static Catalog getCatalog() => getDslCatalog();
}
