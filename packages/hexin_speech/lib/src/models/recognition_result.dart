// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Result of a speech recognition operation.
class RecognitionResult {
  /// The recognized text.
  final String text;

  /// Whether this is a final result.
  ///
  /// If true, this is the final recognition for the current utterance.
  /// If false, this is a partial (interim) result that may change.
  final bool isFinal;

  /// Confidence score for the recognition (0.0 to 1.0).
  ///
  /// Higher values indicate higher confidence.
  /// May be 0.0 if confidence is not available.
  final double confidence;

  /// Timestamp when this result was generated.
  final DateTime timestamp;

  /// Whether this result marks the end of an utterance (endpoint).
  ///
  /// When true, the recognizer has detected silence or
  /// other indicators that the speaker has finished speaking.
  final bool isEndpoint;

  /// Duration of the recognized speech in seconds.
  ///
  /// May be 0.0 if duration is not available.
  final double duration;

  /// The volume level of the audio (0.0 to 1.0).
  final double volume;

  const RecognitionResult({
    required this.text,
    required this.isFinal,
    this.confidence = 0.0,
    required this.timestamp,
    this.isEndpoint = false,
    this.duration = 0.0,
    this.volume = 0.0,
  });

  /// Create an empty result.
  RecognitionResult.empty()
      : text = '',
        isFinal = false,
        confidence = 0.0,
        timestamp = DateTime.now(),
        isEndpoint = false,
        duration = 0.0,
        volume = 0.0;

  /// Create a copy with some fields replaced.
  RecognitionResult copyWith({
    String? text,
    bool? isFinal,
    double? confidence,
    DateTime? timestamp,
    bool? isEndpoint,
    double? duration,
    double? volume,
  }) {
    return RecognitionResult(
      text: text ?? this.text,
      isFinal: isFinal ?? this.isFinal,
      confidence: confidence ?? this.confidence,
      timestamp: timestamp ?? this.timestamp,
      isEndpoint: isEndpoint ?? this.isEndpoint,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
    );
  }

  @override
  String toString() {
    return 'RecognitionResult('
        'text: "$text", '
        'isFinal: $isFinal, '
        'confidence: ${confidence.toStringAsFixed(2)}, '
        'isEndpoint: $isEndpoint'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RecognitionResult &&
        other.text == text &&
        other.isFinal == isFinal &&
        other.confidence == confidence &&
        other.isEndpoint == isEndpoint;
  }

  @override
  int get hashCode {
    return Object.hash(text, isFinal, confidence, isEndpoint);
  }
}
