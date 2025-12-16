// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Configuration for AI backend selection.
enum AiBackend {
  /// Use Google Generative AI with API key (for rapid prototyping).
  googleGenerativeAi,

  /// Use Firebase AI Logic (recommended for production).
  firebase,
}

/// The AI backend to use.
///
/// Change this value to switch between backends:
/// - [AiBackend.googleGenerativeAi]: Quick setup with API key
/// - [AiBackend.firebase]: Production-ready with Firebase
const AiBackend aiBackend = AiBackend.googleGenerativeAi;
