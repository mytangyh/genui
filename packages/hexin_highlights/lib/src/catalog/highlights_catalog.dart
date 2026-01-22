// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/genui.dart';
import 'package:hexin_ai_ui/hexin_ai_ui.dart';

/// Catalog for highlights feature.
///
/// Provides the complete set of catalog items needed for rendering
/// highlights DSL content. Uses AiUiCatalog which contains all components.
class HighlightsCatalog {
  HighlightsCatalog._();

  /// Returns the catalog with all highlights-related components.
  static Catalog getCatalog() {
    return AiUiCatalog.getCatalog();
  }
}
