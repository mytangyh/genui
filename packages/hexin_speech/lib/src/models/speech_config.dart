// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Configuration for speech recognition.
class SpeechConfig {
  /// Language locale (e.g., 'zh_CN' for Mandarin Chinese).
  final String locale;

  /// Audio sample rate in Hz.
  ///
  /// Common values: 16000, 44100, 48000
  /// Sherpa-ONNX typically uses 16000 Hz.
  final int sampleRate;

  /// Number of audio channels.
  ///
  /// Typically 1 (mono) for speech recognition.
  final int numChannels;

  /// Custom model path.
  ///
  /// If null, the default model for the locale will be loaded.
  /// If provided, should point to a directory containing model files.
  final String? modelPath;

  /// Whether to automatically download the model if not found locally.
  ///
  /// If false and model is not cached, initialization will fail.
  final bool autoDownloadModel;

  /// Enable voice activity detection (VAD).
  ///
  /// When enabled, the recognizer will automatically detect
  /// speech endpoints and segment the audio.
  final bool enableVad;

  /// Maximum duration in seconds before forcing an endpoint.
  ///
  /// Only used when [enableVad] is true.
  final double maxSilenceSeconds;

  /// Whether to enable debug logging.
  final bool enableDebugLogging;

  const SpeechConfig({
    this.locale = 'zh_CN',
    this.sampleRate = 16000,
    this.numChannels = 1,
    this.modelPath,
    this.autoDownloadModel = true,
    this.enableVad = true,
    this.maxSilenceSeconds = 2.0,
    this.enableDebugLogging = false,
  });

  /// Create a copy with some fields replaced.
  SpeechConfig copyWith({
    String? locale,
    int? sampleRate,
    int? numChannels,
    String? modelPath,
    bool? autoDownloadModel,
    bool? enableVad,
    double? maxSilenceSeconds,
    bool? enableDebugLogging,
  }) {
    return SpeechConfig(
      locale: locale ?? this.locale,
      sampleRate: sampleRate ?? this.sampleRate,
      numChannels: numChannels ?? this.numChannels,
      modelPath: modelPath ?? this.modelPath,
      autoDownloadModel: autoDownloadModel ?? this.autoDownloadModel,
      enableVad: enableVad ?? this.enableVad,
      maxSilenceSeconds: maxSilenceSeconds ?? this.maxSilenceSeconds,
      enableDebugLogging: enableDebugLogging ?? this.enableDebugLogging,
    );
  }

  @override
  String toString() {
    return 'SpeechConfig('
        'locale: $locale, '
        'sampleRate: $sampleRate, '
        'modelPath: $modelPath, '
        'autoDownloadModel: $autoDownloadModel'
        ')';
  }
}
