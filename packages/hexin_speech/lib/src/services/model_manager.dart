// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/speech_error.dart';

/// Manages downloading and caching of sherpa-onnx models.
class ModelManager {
  static final _log = Logger('ModelManager');

  /// Base URL for model downloads.
  ///
  /// Using a lightweight Chinese streaming model from Hugging Face.
  static const String _baseUrl = 'https://huggingface.co/csukuangfj/'
      'sherpa-onnx-streaming-zipformer-zh-14M-2023-02-23/resolve/main';

  /// Required model files.
  static const List<String> _requiredFiles = [
    'encoder-epoch-99-avg-1.onnx',
    'decoder-epoch-99-avg-1.onnx',
    'joiner-epoch-99-avg-1.onnx',
    'tokens.txt',
  ];

  /// Get the model cache directory.
  Future<Directory> _getModelCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory(p.join(appDir.path, 'sherpa_models', 'zh_CN'));
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir;
  }

  /// Get the path to a model for the given locale.
  ///
  /// Returns the directory path containing the model files.
  /// If [autoDownload] is true and model is not cached, will download it.
  ///
  /// Throws [ModelError] if model cannot be loaded or downloaded.
  Future<String> getModelPath({
    String locale = 'zh_CN',
    bool autoDownload = true,
    void Function(String fileName, double progress)? onProgress,
  }) async {
    final modelDir = await _getModelCacheDir();

    // Check if model is already cached
    if (await _isModelCached(modelDir)) {
      _log.info('Model found in cache: ${modelDir.path}');
      return modelDir.path;
    }

    if (!autoDownload) {
      throw const ModelError(
        'Model not found in cache and autoDownload is disabled',
      );
    }

    // Download the model
    _log.info('Model not cached, downloading...');
    await downloadModel(modelDir.path, onProgress: onProgress);

    return modelDir.path;
  }

  /// Check if all required model files are cached.
  Future<bool> _isModelCached(Directory modelDir) async {
    for (final fileName in _requiredFiles) {
      final file = File(p.join(modelDir.path, fileName));
      if (!await file.exists()) {
        return false;
      }
    }
    return true;
  }

  /// Download model files to the specified directory.
  ///
  /// [onProgress] is called for each file with (fileName, downloaded, total).
  /// Throws [NetworkError] if download fails.
  Future<void> downloadModel(
    String targetPath, {
    void Function(String fileName, double progress)? onProgress,
  }) async {
    _log.info('Downloading model to $targetPath');

    final targetDir = Directory(targetPath);
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    try {
      for (var i = 0; i < _requiredFiles.length; i++) {
        final fileName = _requiredFiles[i];
        if (onProgress != null) {
          onProgress(fileName, i / _requiredFiles.length);
        }
        await _downloadFile(fileName, targetPath);
      }
      if (onProgress != null) {
        onProgress('Complete', 1.0);
      }
      _log.info('Model download complete');
    } catch (e, stack) {
      _log.severe('Model download failed', e, stack);
      throw NetworkError('Failed to download model: $e', cause: e);
    }
  }

  /// Download a single file.
  Future<void> _downloadFile(String fileName, String targetPath) async {
    final url = '$_baseUrl/$fileName';
    _log.info('Downloading $fileName from $url');

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw NetworkError(
        'Failed to download $fileName: HTTP ${response.statusCode}',
      );
    }

    final file = File(p.join(targetPath, fileName));
    await file.writeAsBytes(response.bodyBytes);

    _log.info('Downloaded $fileName (${response.bodyBytes.length} bytes)');
  }

  /// List all cached models.
  Future<List<String>> listCachedModels() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory(p.join(appDir.path, 'sherpa_models'));

    if (!await modelsDir.exists()) {
      return [];
    }

    final models = <String>[];
    await for (final entity in modelsDir.list()) {
      if (entity is Directory) {
        models.add(p.basename(entity.path));
      }
    }

    return models;
  }

  /// Delete a cached model.
  Future<void> deleteModel(String locale) async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory(p.join(appDir.path, 'sherpa_models', locale));

    if (await modelDir.exists()) {
      await modelDir.delete(recursive: true);
      _log.info('Deleted model: $locale');
    }
  }

  /// Get the total size of cached models in bytes.
  Future<int> getCacheSize() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory(p.join(appDir.path, 'sherpa_models'));

    if (!await modelsDir.exists()) {
      return 0;
    }

    var totalSize = 0;
    await for (final entity in modelsDir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }

    return totalSize;
  }

  /// Clear all cached models.
  Future<void> clearCache() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory(p.join(appDir.path, 'sherpa_models'));

    if (await modelsDir.exists()) {
      await modelsDir.delete(recursive: true);
      _log.info('Cleared all model cache');
    }
  }
}
