// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'models/recognition_result.dart';
import 'models/speech_config.dart';
import 'models/speech_error.dart';

/// Abstract interface for speech recognition engines.
///
/// Implementations should handle:
/// - Initialization and configuration
/// - Real-time audio streaming
/// - Recognition result callbacks
/// - Resource cleanup
abstract class SpeechRecognizer {
  /// Initialize the speech recognizer with the given configuration.
  ///
  /// This may involve:
  /// - Loading models
  /// - Requesting permissions
  /// - Setting up audio input
  ///
  /// Throws [SpeechError] if initialization fails.
  Future<void> initialize(
    SpeechConfig config, {
    void Function(String fileName, double progress)? onProgress,
  });

  /// Start listening for speech input.
  ///
  /// Returns a stream of [RecognitionResult] containing both
  /// partial (interim) and final recognition results.
  ///
  /// The stream will emit results as speech is detected and recognized.
  /// Set [RecognitionResult.isFinal] to true in the result when a
  /// complete utterance is recognized.
  ///
  /// Throws [SpeechError] if not initialized or already listening.
  Stream<RecognitionResult> startListening();

  /// Stop listening and close the recognition stream.
  ///
  /// This will:
  /// - Stop audio capture
  /// - Process any remaining audio
  /// - Close the result stream
  Future<void> stopListening();

  /// Cancel the current recognition session.
  ///
  /// Similar to [stopListening] but may discard partial results.
  Future<void> cancelListening();

  /// Recognize speech from an audio file.
  ///
  /// This is a non-streaming alternative for processing
  /// pre-recorded audio files.
  ///
  /// Returns the final recognition result.
  ///
  /// Throws [SpeechError] if file cannot be read or recognized.
  Future<RecognitionResult> recognizeFile(String filePath);

  /// Whether the recognizer is currently listening.
  bool get isListening;

  /// Whether the recognizer has been initialized.
  bool get isInitialized;

  /// Release all resources held by this recognizer.
  ///
  /// After calling this, the recognizer cannot be used
  /// until [initialize] is called again.
  void dispose();
}
