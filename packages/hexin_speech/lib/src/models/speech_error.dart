// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Base class for all speech recognition errors.
class SpeechError implements Exception {
  /// Error message.
  final String message;

  /// Error code.
  final String code;

  /// Optional underlying error.
  final Object? cause;

  const SpeechError(this.message, {this.code = 'unknown', this.cause});

  @override
  String toString() =>
      'SpeechError($code): $message${cause != null ? ' (cause: $cause)' : ''}';
}

/// Error during initialization.
class InitializationError extends SpeechError {
  const InitializationError(super.message, {super.cause})
      : super(code: 'initialization_error');
}

/// Error related to permissions.
class PermissionError extends SpeechError {
  const PermissionError(super.message, {super.cause})
      : super(code: 'permission_error');
}

/// Error during model loading or downloading.
class ModelError extends SpeechError {
  const ModelError(super.message, {super.cause}) : super(code: 'model_error');
}

/// Error during audio recording.
class AudioError extends SpeechError {
  const AudioError(super.message, {super.cause}) : super(code: 'audio_error');
}

/// Error during recognition.
class RecognitionError extends SpeechError {
  const RecognitionError(super.message, {super.cause})
      : super(code: 'recognition_error');
}

/// Network error during model download.
class NetworkError extends SpeechError {
  const NetworkError(super.message, {super.cause})
      : super(code: 'network_error');
}
