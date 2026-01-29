# hexin_speech

Speech recognition package for Hexin AI using [sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx) for offline automatic speech recognition (ASR).

## Features

- ✅ **Offline Speech Recognition**: Fully offline ASR using sherpa-onnx
- ✅ **Real-time Streaming**: Support for real-time speech-to-text
- ✅ **Chinese Language Support**: Optimized for Mandarin Chinese
- ✅ **Voice Activity Detection**: Built-in VAD for endpoint detection
- ✅ **Model Management**: Automatic model download and caching
- ✅ **Cross-platform**: Android, iOS, Windows, macOS, Linux

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  hexin_speech:
    path: ../hexin_speech  # For local development
```

## Quick Start

```dart
import 'package:hexin_speech/hexin_speech.dart';

// Initialize the recognizer
final recognizer = SherpaEngine();
await recognizer.initialize(SpeechConfig(
  locale: 'zh_CN',
  autoDownloadModel: true,
));

// Start listening
recognizer.startListening().listen((result) {
  print('Recognized: ${result.text}');
  
  if (result.isFinal) {
    print('Final result: ${result.text}');
  }
});

// Stop listening
await recognizer.stopListening();
```

## Configuration

```dart
final config = SpeechConfig(
  locale: 'zh_CN',           // Language locale
  sampleRate: 16000,         // Audio sample rate
  autoDownloadModel: true,   // Auto download model if not cached
  modelPath: null,           // Custom model path (optional)
);
```

## Model Management

Models are automatically downloaded and cached on first use. Default model directory:
- **Android**: `/data/data/<app>/files/sherpa_models/`
- **iOS**: `<App Documents>/sherpa_models/`
- **Windows/macOS/Linux**: `<User Documents>/sherpa_models/`

## License

See the [LICENSE](LICENSE) file for details.
