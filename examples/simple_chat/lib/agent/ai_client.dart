// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:logging/logging.dart';

import '../primitives/climbing/climbing_db.dart';
import 'api_key/api_key.dart';

/// An abstract interface for AI clients.
abstract interface class AiClient {
  /// Sends a message stream request to the AI service.
  ///
  /// [prompt] is the user's message.
  /// [history] is the conversation history.
  Stream<String> sendStream(
    String prompt, {
    required List<dartantic.ChatMessage> history,
  });

  /// Dispose of resources.
  void dispose();
}

/// An implementation of [AiClient] using `package:dartantic_ai`.
class DartanticAiClient implements AiClient {
  DartanticAiClient({String? modelName}) {
    const configuredKey = String.fromEnvironment('GENUI_API_KEY');
    final String key = configuredKey.isEmpty ? apiKey() : configuredKey;
    const baseUrl = String.fromEnvironment('GENUI_BASE_URL');
    const providerName = String.fromEnvironment(
      'GENUI_PROVIDER',
      defaultValue: 'google',
    );
    final Uri? endpoint = baseUrl.isEmpty ? null : Uri.parse(baseUrl);
    final dartantic.Provider provider = switch (providerName) {
      'google' => dartantic.GoogleProvider(apiKey: key, baseUrl: endpoint),
      'openai' => dartantic.OpenAIProvider(apiKey: key, baseUrl: endpoint),
      _ => throw ArgumentError.value(providerName, 'GENUI_PROVIDER'),
    };
    _agent = dartantic.Agent.forProvider(
      provider,
      chatModelName: modelName ??
          const String.fromEnvironment(
            'GENUI_MODEL',
            defaultValue: 'gemini-3-flash-preview',
          ),
      tools: [
        dartantic.Tool(
          name: 'listClimbingLocations',
          description: 'Lists all available climbing locations.',
          onCall: (args) {
            Logger('SimpleChatTools').info('listClimbingLocations executed');
            return climbingLocations.map((e) => e.toJson()).toList();
          },
        ),
      ],
    );
  }

  late final dartantic.Agent _agent;

  @override
  Stream<String> sendStream(
    String prompt, {
    required List<dartantic.ChatMessage> history,
  }) async* {
    final Stream<dartantic.ChatResult<String>> stream = _agent.sendStream(
      prompt,
      history: history,
    );

    await for (final result in stream) {
      if (result.output.isNotEmpty) {
        yield result.output;
      }
    }
  }

  @override
  void dispose() {
    // Dartantic Agent/Provider doesn't strictly require disposal currently,
    // but good to have the hook.
  }
}
