// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

/// A ContentGenerator that connects to a custom backend API using SSE for streaming.
class SSEContentGenerator implements ContentGenerator {
  /// Creates a [SSEContentGenerator].
  SSEContentGenerator({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.systemInstruction,
    this.catalog,
  });

  /// The base URL of the custom API.
  final String baseUrl;

  /// The API key for authentication.
  final String apiKey;

  /// The model name to use.
  final String model;

  /// Optional system instruction.
  final String? systemInstruction;

  /// The catalog of available components.
  final Catalog? catalog;

  final _a2uiMessageController = StreamController<A2uiMessage>.broadcast();
  final _textResponseController = StreamController<String>.broadcast();
  final _errorController = StreamController<ContentGeneratorError>.broadcast();
  final _isProcessing = ValueNotifier<bool>(false);
  final _uuid = const Uuid();

  http.Client? _client;

  @override
  Stream<A2uiMessage> get a2uiMessageStream => _a2uiMessageController.stream;

  @override
  Stream<String> get textResponseStream => _textResponseController.stream;

  @override
  Stream<ContentGeneratorError> get errorStream => _errorController.stream;

  @override
  ValueListenable<bool> get isProcessing => _isProcessing;

  @override
  Future<void> sendRequest(
    ChatMessage message, {
    Iterable<ChatMessage>? history,
    A2UiClientCapabilities? clientCapabilities,
  }) async {
    if (_isProcessing.value) {
      _cancelRequest();
    }

    _isProcessing.value = true;
    _client = http.Client();

    try {
      String userText = '';
      if (message is UserMessage) {
        userText = message.text;
      } else if (message is UserUiInteractionMessage) {
        userText = message.text;
      }

      final messages = <Map<String, Object?>>[];

      // 1. Prepare System Instruction
      if (systemInstruction != null && systemInstruction!.isNotEmpty) {
        messages.add({'role': 'system', 'content': systemInstruction});
      }

      // 2. Prepare History
      if (history != null) {
        for (final msg in history) {
          if (msg is UserMessage) {
            messages.add({'role': 'user', 'content': msg.text});
          } else if (msg is AiTextMessage) {
            messages.add({'role': 'assistant', 'content': msg.text});
          }
        }
      }

      // 3. Add Current Message
      messages.add({'role': 'user', 'content': userText});

      final requestBody = {
        'model': model,
        'messages': messages,
        'stream': true,
        'temperature': 0.7,
      };

      debugPrint('SSE Request to $baseUrl: $requestBody');

      final request = http.Request('POST', Uri.parse(baseUrl));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'Accept': 'text/event-stream',
      });
      request.body = jsonEncode(requestBody);

      final streamedResponse = await _client!.send(request);

      if (streamedResponse.statusCode != 200) {
        // Consume the stream to avoid hanging connection?
        // But we are throwing anyway.
        // Let's try to read body if possible for error message
        final body = await streamedResponse.stream.bytesToString();
        throw Exception(
            'API Request failed: ${streamedResponse.statusCode} - $body');
      }

      await _processSSEStream(streamedResponse.stream);
    } catch (e, stackTrace) {
      if (e.toString().contains('ClientException') && !_isProcessing.value) {
        // Likely cancelled, ignore or log
        debugPrint('Request cancelled');
      } else {
        debugPrint('ERROR processing SSE response: $e');
        _errorController.add(ContentGeneratorError(e, stackTrace));
      }
    } finally {
      _isProcessing.value = false;
      _client?.close();
      _client = null;
    }
  }

  void _cancelRequest() {
    _client?.close();
    _isProcessing.value = false;
  }

  Future<void> _processSSEStream(Stream<List<int>> byteStream) async {
    final buffer =
        StringBuffer(); // For accumulating full content for later if needed (e.g. tool calls)

    // transform to utf8 lines
    await for (final chunk in byteStream.transform(utf8.decoder)) {
      // SSE can split lines across chunks, simple splitting by \n works if chunks end with \n
      // Ideally we should double buffer, but for simple implementation relying on Flutter/Dart's transform:
      // LineSplitter is safer

      const LineSplitter().convert(chunk).forEach((line) {
        if (line.trim().isEmpty) return;
        if (line.startsWith('data: ')) {
          final dataStr = line.substring(6);
          if (dataStr == '[DONE]') return;

          try {
            final data = jsonDecode(dataStr);
            // Check for choices -> delta -> content
            if (data['choices'] != null &&
                (data['choices'] as List).isNotEmpty) {
              final choice = data['choices'][0];
              final delta = choice['delta'];
              if (delta != null && delta['content'] != null) {
                final content = delta['content'] as String;
                if (content.isNotEmpty) {
                  _textResponseController.add(content);
                  buffer.write(content);
                }
              }
            }
          } catch (e) {
            debugPrint('Error parsing SSE data line: $dataStr, error: $e');
          }
        }
      });
    }

    // If we wanted to support DSL or Tool Calls via SSE, we would parse `buffer.toString()` here, similar to CustomContentGenerator
    // For "General LLM Chatbot", we primarily focus on text first as per plan.
    _processContent(buffer.toString());
  }

  void _processContent(String content) {
    // Check for DSL blocks in the complete accumulated content
    final dslPattern = RegExp(
      r'```(dsl|web)\s*\n([\s\S]*?)```',
      multiLine: true,
    );
    for (final match in dslPattern.allMatches(content)) {
      final language = match.group(1);
      final jsonString = match.group(2)?.trim();
      if (jsonString != null && jsonString.isNotEmpty && language == 'dsl') {
        try {
          final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
          final surfaceId = _uuid.v4();
          _a2uiMessageController.add(
            SurfaceUpdate(
              surfaceId: surfaceId,
              components: [Component(id: 'root', componentProperties: decoded)],
            ),
          );
          _a2uiMessageController.add(
            BeginRendering(surfaceId: surfaceId, root: 'root'),
          );
        } catch (e) {
          debugPrint('Error parsing DSL from stream: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _cancelRequest();
    _a2uiMessageController.close();
    _textResponseController.close();
    _errorController.close();
    _isProcessing.dispose();
  }
}
