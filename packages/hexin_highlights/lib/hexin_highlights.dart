// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Highlights business feature for Hexin applications.
///
/// This library provides the complete highlights feature including:
/// - Service for fetching highlights data
/// - Response models
/// - Catalog configuration
library hexin_highlights;

// Re-export dependencies for convenience
export 'package:hexin_ai_ui/hexin_ai_ui.dart';
export 'package:hexin_dsl/hexin_dsl.dart';

// Models
export 'src/models/highlights_response.dart';

// Services
export 'src/services/highlights_service.dart';

// Catalog
export 'src/catalog/highlights_catalog.dart';

// UI
export 'src/ui/highlights_page.dart';
