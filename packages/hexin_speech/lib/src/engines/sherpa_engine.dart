// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../models/recognition_result.dart';
import '../models/speech_config.dart';
import '../models/speech_error.dart';
import '../services/model_manager.dart';
import '../speech_recognizer.dart';

/// Speech recognizer implementation using sherpa-onnx.
///
/// Provides offline, real-time speech recognition using
/// the sherpa-onnx framework with next-gen Kaldi models.
class SherpaEngine implements SpeechRecognizer {
  static final _log = Logger('SherpaEngine');

  final ModelManager _modelManager = ModelManager();
  final AudioRecorder _audioRecorder = AudioRecorder();

  sherpa.OnlineRecognizer? _recognizer;
  sherpa.OnlineStream? _stream;
  SpeechConfig? _config;

  StreamController<RecognitionResult>? _resultController;
  StreamSubscription<Uint8List>? _audioSubscription;

  String _lastText = '';

  /// Whether the recognizer is currently listening.
  @override
  bool get isListening => _audioSubscription != null;

  @override
  bool get isInitialized => _recognizer != null;

  @override
  Future<void> initialize(
    SpeechConfig config, {
    void Function(String fileName, double progress)? onProgress,
  }) async {
    if (isInitialized) {
      _log.warning('Already initialized');
      return;
    }

    _config = config;

    try {
      // Get model path (download if needed)
      final modelPath = await _modelManager.getModelPath(
        locale: config.locale,
        level: config.modelLevel,
        autoDownload: config.autoDownloadModel,
        onProgress: onProgress,
      );

      _log.info('Initializing sherpa-onnx with model: $modelPath');

      // Initialize sherpa-onnx bindings
      sherpa.initBindings();

      // Create model configuration
      final modelConfig = sherpa.OnlineModelConfig(
        tokens: p.join(modelPath, 'tokens.txt'),
        transducer: sherpa.OnlineTransducerModelConfig(
          encoder: p.join(modelPath, 'encoder-epoch-99-avg-1.onnx'),
          decoder: p.join(modelPath, 'decoder-epoch-99-avg-1.onnx'),
          joiner: p.join(modelPath, 'joiner-epoch-99-avg-1.onnx'),
        ),
        numThreads: 2,
        provider: 'cpu',
        debug: config.enableDebugLogging,
      );

      // Create recognizer configuration
      final recognizerConfig = sherpa.OnlineRecognizerConfig(
        model: modelConfig,
        enableEndpoint: config.enableVad,
      );

      // Create recognizer and stream
      _recognizer = sherpa.OnlineRecognizer(recognizerConfig);
      _stream = _recognizer!.createStream();

      _log.info('Sherpa-onnx initialized successfully');
    } catch (e, stack) {
      _log.severe('Initialization failed', e, stack);
      throw InitializationError(
        'Failed to initialize sherpa-onnx: $e',
        cause: e,
      );
    }
  }

  @override
  Stream<RecognitionResult> startListening() {
    if (!isInitialized) {
      throw const InitializationError('Recognizer not initialized');
    }

    if (isListening) {
      throw const AudioError('Already listening');
    }

    _resultController = StreamController<RecognitionResult>.broadcast();
    _lastText = '';

    _startAudioCapture();

    return _resultController!.stream;
  }

  Future<void> _startAudioCapture() async {
    try {
      // Check permissions
      if (!await _audioRecorder.hasPermission()) {
        throw const PermissionError('Microphone permission not granted');
      }

      // Configure audio recording
      const recordConfig = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      );

      // Start audio stream
      final audioStream = await _audioRecorder.startStream(recordConfig);

      // Process audio data
      _audioSubscription = audioStream.listen(
        _processAudioData,
        onError: (Object error) {
          _log.severe('Audio stream error: $error');
          _resultController?.addError(
            AudioError('Audio stream error: $error', cause: error),
          );
        },
        onDone: () {
          _log.info('Audio stream closed');
        },
      );

      _log.info('Audio capture started');
    } catch (e, stack) {
      _log.severe('Failed to start audio capture', e, stack);
      throw AudioError('Failed to start audio capture: $e', cause: e);
    }
  }

  void _processAudioData(Uint8List audioData) {
    if (audioData.isEmpty) {
      _log.warning('Received empty audio data chunk');
      return;
    }

    try {
      // Convert PCM16 bytes to Float32 samples
      final samples = _convertBytesToFloat32(audioData);

      // Calculate RMS and max level for debugging
      double sum = 0;
      double maxAbs = 0;
      for (final s in samples) {
        sum += s * s;
        if (s.abs() > maxAbs) maxAbs = s.abs();
      }
      final rms = sqrt(sum / samples.length);

      // Normalize to 0.0-1.0 for UI display
      // Using a slightly more aggressive scaling for weak signals
      final volume = (rms * 5).clamp(0.0, 1.0);

      if (rms < 0.001) {
        _log.fine('Silence/Low volume detected (RMS: '
            '${rms.toStringAsFixed(6)}, Max: ${maxAbs.toStringAsFixed(6)})');
      }

      // Feed audio to recognizer
      _stream!.acceptWaveform(
        samples: samples,
        sampleRate: _config!.sampleRate,
      );

      // Decode as much as possible
      var decodeCount = 0;
      while (_recognizer!.isReady(_stream!)) {
        _recognizer!.decode(_stream!);
        decodeCount++;
      }

      if (decodeCount > 0) {
        _log.finest('Decoded $decodeCount segments');
      }

      // Get current recognition result
      final result = _recognizer!.getResult(_stream!);
      final text = result.text;
      final isEndpoint = _recognizer!.isEndpoint(_stream!);

      // Log raw text for debugging if there is ANY content
      if (text.isNotEmpty) {
        _log.fine('Current transcript: "$text" (isFinal: $isEndpoint)');
      }

      // Emit result if text changed, endpoint detected, or just updating volume
      if ((text.isNotEmpty && text != _lastText) || isEndpoint) {
        _resultController!.add(RecognitionResult(
          text: text,
          isFinal: isEndpoint,
          timestamp: DateTime.now(),
          isEndpoint: isEndpoint,
          volume: volume,
        ));
        _lastText = text;
      } else if (volume > 0.01) {
        // Even if text didn't change, we might want to update volume UI
        _resultController!.add(RecognitionResult(
          text: _lastText,
          isFinal: false,
          timestamp: DateTime.now(),
          isEndpoint: false,
          volume: volume,
        ));
      }

      // Reset stream on endpoint
      if (isEndpoint) {
        _log.info('Endpoint detected, resetting stream. Final text: "$text"');
        _recognizer!.reset(_stream!);
        _lastText = '';
      }
    } catch (e, stack) {
      _log.severe('Error processing audio data', e, stack);
      _resultController?.addError(
        RecognitionError('Error processing audio: $e', cause: e),
      );
    }
  }

  Float32List _convertBytesToFloat32(Uint8List bytes, {int channels = 1}) {
    Int16List int16List;
    if (bytes.offsetInBytes % 2 != 0) {
      // If the buffer offset is not aligned to 2 bytes, we must copy to a
      // new aligned buffer before creating the Int16List view.
      final aligned = Uint8List.fromList(bytes);
      int16List = Int16List.view(aligned.buffer);
    } else {
      int16List = Int16List.view(
        bytes.buffer,
        bytes.offsetInBytes,
        bytes.lengthInBytes ~/ 2,
      );
    }

    if (channels == 1) {
      final floatList = Float32List(int16List.length);
      for (var i = 0; i < int16List.length; i++) {
        floatList[i] = int16List[i] / 32768.0;
      }
      return floatList;
    } else {
      // Extract only the first channel for multi-channel audio
      final floatList = Float32List(int16List.length ~/ channels);
      for (var i = 0; i < floatList.length; i++) {
        floatList[i] = int16List[i * channels] / 32768.0;
      }
      return floatList;
    }
  }

  @override
  Future<void> stopListening() async {
    if (!isListening) {
      return;
    }

    try {
      await _audioSubscription?.cancel();
      _audioSubscription = null;

      await _audioRecorder.stop();

      // Reset stream for next use
      _stream?.free();
      _stream = _recognizer?.createStream();

      await _resultController?.close();
      _resultController = null;

      _lastText = '';

      _log.info('Stopped listening');
    } catch (e, stack) {
      _log.severe('Error stopping listener', e, stack);
    }
  }

  @override
  Future<void> cancelListening() async {
    await stopListening();
    _log.info('Cancelled listening');
  }

  @override
  Future<RecognitionResult> recognizeFile(String filePath) async {
    if (!isInitialized) {
      throw const InitializationError('Recognizer not initialized');
    }

    final file = File(filePath);
    if (!await file.exists()) {
      throw AudioError('File not found: $filePath');
    }

    try {
      final bytes = await file.readAsBytes();
      _log.info('File read: ${file.path}, size: ${bytes.length} bytes');

      var offset = 0;
      int channels = 1;
      int sampleRate = 16000;

      if (bytes.length > 44 &&
          String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF') {
        _log.info('WAV header (RIFF) detected');

        // Parse fmt chunk to get channels and sample rate
        // Typically starts at offset 12
        for (int i = 12; i < bytes.length - 20; i++) {
          if (String.fromCharCodes(bytes.sublist(i, i + 3)) == 'fmt') {
            final fmtChunkOffset = i + 8;
            channels =
                bytes[fmtChunkOffset + 2] | (bytes[fmtChunkOffset + 3] << 8);
            sampleRate = bytes[fmtChunkOffset + 4] |
                (bytes[fmtChunkOffset + 5] << 8) |
                (bytes[fmtChunkOffset + 6] << 16) |
                (bytes[fmtChunkOffset + 7] << 24);
            _log.info('WAV Info: Channels=$channels, SampleRate=$sampleRate');
            break;
          }
        }

        // Find data chunk
        for (int i = 12; i < bytes.length - 8; i++) {
          if (String.fromCharCodes(bytes.sublist(i, i + 4)) == 'data') {
            offset = i + 8;
            _log.info('WAV data chunk found at offset $offset');
            break;
          }
        }

        if (offset == 0) {
          _log.warning(
              'Could not find data chunk in WAV, falling back to offset 44');
          offset = 44;
        }
      } else {
        final header = bytes.take(4).toList();
        _log.warning('No RIFF header found. First 4 bytes: $header. '
            'Treating as raw PCM16 Mono.');
      }

      if (sampleRate != 16000) {
        _log.warning('Sample rate $sampleRate != 16000. '
            'Recognition will be inaccurate as no resampling is performed.');
      }

      final pcmData = bytes.sublist(offset);
      _log.info('Processing ${pcmData.length} bytes of audio data');

      final samples = _convertBytesToFloat32(pcmData, channels: channels);
      _log.info('Extracted ${samples.length} float32 samples from channel 0');

      final fileStream = _recognizer!.createStream();
      fileStream.acceptWaveform(
        samples: samples,
        sampleRate: _config!.sampleRate,
      );
      fileStream.inputFinished(); // Mark end of stream

      // Must loop decode for large files
      int decodeCount = 0;
      while (_recognizer!.isReady(fileStream)) {
        _recognizer!.decode(fileStream);
        decodeCount++;
      }
      _log.info('Decoded $decodeCount segments for file');

      final result = _recognizer!.getResult(fileStream);
      _log.info('File recognition result: "${result.text}"');
      fileStream.free();

      return RecognitionResult(
        text: result.text,
        isFinal: true,
        timestamp: DateTime.now(),
      );
    } catch (e, stack) {
      _log.severe('File recognition failed', e, stack);
      throw RecognitionError(
        'File recognition failed: $e',
        cause: e,
      );
    }
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    _audioRecorder.dispose();
    _resultController?.close();
    _stream?.free();
    _recognizer?.free();

    _recognizer = null;
    _stream = null;
    _config = null;

    _log.info('Disposed');
  }
}
