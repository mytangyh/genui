// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage chatbot settings persistence.
class SettingsService {
  static const String _keyBaseUrl = 'custom_base_url';
  static const String _keyApiKey = 'custom_api_key';
  static const String _keyModel = 'custom_model';

  /// Saves the chatbot settings.
  Future<void> saveSettings({
    required String baseUrl,
    required String apiKey,
    required String model,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, baseUrl);
    await prefs.setString(_keyApiKey, apiKey);
    await prefs.setString(_keyModel, model);
  }

  /// Loads the chatbot settings.
  ///
  /// Returns a map with keys 'baseUrl', 'apiKey', and 'model'.
  /// Returns null if any setting is missing.
  Future<Map<String, String>?> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString(_keyBaseUrl);
    final apiKey = prefs.getString(_keyApiKey);
    final model = prefs.getString(_keyModel);

    if (baseUrl != null && apiKey != null && model != null) {
      return {
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'model': model,
      };
    }
    return null;
  }

  /// Clears the chatbot settings.
  Future<void> clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyBaseUrl);
    await prefs.remove(_keyApiKey);
    await prefs.remove(_keyModel);
  }
}
