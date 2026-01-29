// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hexin_speech/hexin_speech.dart';
import 'package:logging/logging.dart';

void main() {
  // Setup logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hexin Speech Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SpeechHomePage(),
    );
  }
}

class SpeechHomePage extends StatefulWidget {
  const SpeechHomePage({super.key});

  @override
  State<SpeechHomePage> createState() => _SpeechHomePageState();
}

class _SpeechHomePageState extends State<SpeechHomePage> {
  final SpeechRecognizer _recognizer = SherpaEngine();
  final ModelManager _modelManager = ModelManager();
  final TextEditingController _textController = TextEditingController();

  // Configuration
  bool _enableVad = true;
  double _maxSilenceSeconds = 2.0;
  bool _enableDebugLogging = true;
  SpeechModelLevel _modelLevel = SpeechModelLevel.lowLatency;

  // State
  bool _isInitialized = false;
  bool _isInitializing = false;
  String _statusText = 'Not initialized';
  double _downloadProgress = 0.0;
  String _downloadingFile = '';
  String _cacheSize = 'Checking...';
  double _volume = 0.0;

  StreamSubscription<RecognitionResult>? _recognitionSubscription;

  @override
  void initState() {
    super.initState();
    _updateCacheSize();
  }

  Future<void> _updateCacheSize() async {
    final size = await _modelManager.getCacheSize();
    setState(() {
      _cacheSize = '${(size / 1024 / 1024).toStringAsFixed(2)} MB';
    });
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;

    setState(() {
      _isInitializing = true;
      _statusText = 'Initializing...';
      _downloadProgress = 0.0;
    });

    try {
      await _recognizer.initialize(
        SpeechConfig(
          locale: 'zh_CN',
          enableVad: _enableVad,
          maxSilenceSeconds: _maxSilenceSeconds,
          enableDebugLogging: _enableDebugLogging,
          modelLevel: _modelLevel,
          autoDownloadModel: true,
        ),
        onProgress: (fileName, progress) {
          setState(() {
            _downloadingFile = fileName;
            _downloadProgress = progress;
          });
        },
      );

      setState(() {
        _isInitialized = true;
        _isInitializing = false;
        _statusText = 'Ready';
      });
      _updateCacheSize();
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _statusText = 'Error: $e';
      });
    }
  }

  Future<void> _reInitialize() async {
    await _recognizer.stopListening();
    _recognizer.dispose();
    _isInitialized = false;
    await _initialize();
  }

  void _startListening() {
    if (!_isInitialized) return;

    setState(() {
      _statusText = 'Listening...';
      _textController.clear();
    });

    _recognitionSubscription = _recognizer.startListening().listen(
      (result) {
        // ignore: avoid_print
        print('UI RECV: "${result.text}" (final: ${result.isFinal})');
        setState(() {
          _textController.text = result.text;
          _volume = result.volume;
          _statusText =
              result.isFinal ? 'Recognized (final)' : 'Recognizing...';
        });
      },
      onError: (Object error) {
        // ignore: avoid_print
        print('UI ERROR: $error');
        setState(() {
          _statusText = 'Error: $error';
        });
      },
    );
  }

  Future<void> _stopListening() async {
    await _recognitionSubscription?.cancel();
    await _recognizer.stopListening();

    setState(() {
      _statusText = 'Stopped';
      _volume = 0.0;
    });
  }

  Future<void> _pickAndRecognize() async {
    if (!_isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please initialize first')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _statusText = 'Recognizing file...';
        _textController.clear();
      });

      try {
        final recognition =
            await _recognizer.recognizeFile(result.files.single.path!);
        setState(() {
          _textController.text = recognition.text;
          _statusText = 'File recognized';
        });
      } catch (e) {
        setState(() {
          _statusText = 'Error: $e';
        });
      }
    }
  }

  Future<void> _clearCache() async {
    await _modelManager.clearCache();
    setState(() {
      _isInitialized = false;
      _statusText = 'Cache cleared. Needs re-init.';
    });
    _updateCacheSize();
  }

  @override
  void dispose() {
    _recognitionSubscription?.cancel();
    _recognizer.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hexin Speech Pro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 16),
            _buildResultArea(),
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isInitialized
            ? (_recognizer.isListening ? _stopListening : _startListening)
            : _initialize,
        backgroundColor: _recognizer.isListening ? Colors.redAccent : null,
        icon: Icon(_isInitialized
            ? (_recognizer.isListening ? Icons.stop : Icons.mic)
            : Icons.download),
        label: Text(_isInitialized
            ? (_recognizer.isListening ? 'Stop' : 'Listen')
            : 'Init Engine'),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STATUS',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: Colors.white54),
                    ),
                    Text(
                      _statusText,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'CACHE',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: Colors.white54),
                    ),
                    Text(
                      _cacheSize,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
            if (_recognizer.isListening) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    _volume > 0.05 ? Icons.mic : Icons.mic_none,
                    size: 16,
                    color: Color.lerp(
                        Colors.white54, Colors.greenAccent, _volume * 2),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: _volume,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color.lerp(Colors.blue, Colors.red, _volume) ??
                              Colors.blue,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Volume Level',
                style: TextStyle(fontSize: 10, color: Colors.white38),
              ),
            ],
            if (_isInitializing) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                  value: _downloadProgress > 0 ? _downloadProgress : null),
              const SizedBox(height: 4),
              Text(
                _downloadingFile.isNotEmpty
                    ? 'Downloading $_downloadingFile...'
                    : 'Loading model...',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultArea() {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recognized Text',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.copy_all, size: 20),
                    onPressed: () {
                      // Copy to clipboard
                    },
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  readOnly: true,
                  decoration: const InputDecoration(
                    hintText: 'Results will appear here...',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 18, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isInitialized ? _pickAndRecognize : null,
            icon: const Icon(Icons.audio_file),
            label: const Text('File ASR (WAV)'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _textController.clear(),
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear'),
          ),
        ),
      ],
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Engine Settings',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Enable VAD'),
                subtitle: const Text('Automatic endpoint detection'),
                value: _enableVad,
                onChanged: (v) {
                  setModalState(() => _enableVad = v);
                  setState(() => _enableVad = v);
                },
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Max Silence (seconds)'),
              ),
              Slider(
                value: _maxSilenceSeconds,
                min: 0.5,
                max: 5.0,
                divisions: 9,
                label: _maxSilenceSeconds.toStringAsFixed(1),
                onChanged: (v) {
                  setModalState(() => _maxSilenceSeconds = v);
                  setState(() => _maxSilenceSeconds = v);
                },
              ),
              const Divider(height: 32),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Model Accuracy (Higher = More Memory/Net)'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<SpeechModelLevel>(
                  segments: const [
                    ButtonSegment(
                      value: SpeechModelLevel.lowLatency,
                      label: Text('Low Latency'),
                      icon: Icon(Icons.speed),
                    ),
                    ButtonSegment(
                      value: SpeechModelLevel.highAccuracy,
                      label: Text('High Accuracy'),
                      icon: Icon(Icons.high_quality),
                    ),
                  ],
                  selected: {_modelLevel},
                  onSelectionChanged: (Set<SpeechModelLevel> selected) {
                    final newLevel = selected.first;
                    setModalState(() => _modelLevel = newLevel);
                    setState(() => _modelLevel = newLevel);
                  },
                ),
              ),
              const Divider(height: 32),
              SwitchListTile(
                title: const Text('Enable Debug Logging'),
                subtitle: const Text('Show detailed engine logs'),
                value: _enableDebugLogging,
                onChanged: (v) {
                  setModalState(() => _enableDebugLogging = v);
                  setState(() => _enableDebugLogging = v);
                },
              ),
              const Divider(height: 32),
              ListTile(
                leading: const Icon(Icons.delete_sweep, color: Colors.orange),
                title: const Text('Clear Model Cache'),
                onTap: () {
                  Navigator.pop(context);
                  _clearCache();
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _reInitialize();
                  },
                  child: const Text('Apply & Restart Engine'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
