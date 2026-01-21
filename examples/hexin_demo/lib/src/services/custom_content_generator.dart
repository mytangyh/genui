// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

/// A ContentGenerator that connects to a custom backend API.
class CustomContentGenerator implements ContentGenerator {
  /// Creates a [CustomContentGenerator].
  CustomContentGenerator({
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
  }) async {
    if (_isProcessing.value) return;

    _isProcessing.value = true;

    try {
      String userText = '';
      if (message is UserMessage) {
        userText = message.text;
      } else if (message is UserUiInteractionMessage) {
        userText = message.text;
      }

      final messages = <Map<String, Object?>>[];

      // 1. Prepare System Instruction
      String finalSystemInstruction = systemInstruction ?? '';

      // If we have a catalog, we append the instructions on how to use the UI generation tool
      if (catalog != null) {
        final toolName = 'uiGenerationTool';
        final techPrompt = genUiTechPrompt([toolName]);
        finalSystemInstruction = '$finalSystemInstruction\n\n$techPrompt';
      }

      if (finalSystemInstruction.isNotEmpty) {
        messages.add({'role': 'system', 'content': finalSystemInstruction});
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

      // 4. Prepare Tools
      List<Map<String, Object?>>? tools;
      if (catalog != null) {
        final toolDecl = catalogToFunctionDeclaration(
          catalog!,
          'uiGenerationTool',
          'Generates Flutter UI based on user requests.',
        );

        tools = [
          {'type': 'function', 'function': toolDecl.toJson()},
        ];
      }

      final requestBody = {
        'model': model,
        'messages': messages,
        'stream': false,
        'temperature': 0.7,
        if (tools != null) 'tools': tools,
      };

      // Log request details
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('DEBUG: Sending API Request');
      debugPrint('Model: $model');
      debugPrint('Messages count: ${messages.length}');
      debugPrint(
        'Tools: ${tools != null ? "enabled (${tools.length})" : "disabled"}',
      );
      debugPrint('───────────────────────────────────────────────────────');
      debugPrint('Request Body:');
      _printLongString(const JsonEncoder.withIndent('  ').convert(requestBody));
      debugPrint('═══════════════════════════════════════════════════════');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final bodyString = utf8.decode(response.bodyBytes);
        print('DEBUG: Raw Response: $bodyString');

        final data = jsonDecode(bodyString);
        final choice = data['choices'][0];
        final messageData = choice['message'];

        // Handle content if present
        if (messageData['content'] != null &&
            messageData['content'] is String) {
          final content = messageData['content'] as String;
          if (content.isNotEmpty) {
            await _processContent(content, messages);
          }
        }

        // Handle tool calls
        final toolCallsRaw = messageData['tool_calls'];
        if (toolCallsRaw != null) {
          if (toolCallsRaw is List) {
            _handleStandardToolCalls(toolCallsRaw);
          } else {
            print(
              'WARNING: tool_calls is not a List, it is ${toolCallsRaw.runtimeType}: $toolCallsRaw',
            );
          }
        }
      } else {
        throw Exception(
          'API Request failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      print('ERROR processing API response: $e');
      _errorController.add(ContentGeneratorError(e, stackTrace));
    } finally {
      _isProcessing.value = false;
    }
  }

  void _handleStandardToolCalls(List toolCalls) {
    try {
      for (final toolCallJson in toolCalls) {
        if (toolCallJson is! Map) {
          print('WARNING: toolCallJson is not a Map: $toolCallJson');
          continue;
        }
        final function = toolCallJson['function'];
        if (function == null || function is! Map) continue;

        final name = function['name'] as String?;
        if (name == null) continue;

        final arguments = function['arguments'];

        // OpenAI format arguments are usually stringified JSON
        Map<String, Object?> argsMap = {};
        try {
          if (arguments is String) {
            final decoded = jsonDecode(arguments);
            if (decoded is Map<String, dynamic>) {
              argsMap = decoded;
            }
          } else if (arguments is Map) {
            argsMap = Map<String, Object?>.from(arguments);
          }
        } catch (e) {
          print('Error decoding tool arguments: $e\nArguments: $arguments');
          continue;
        }

        if (name == 'uiGenerationTool') {
          // Heuristic Fix: If 'components' is a string (double-encoded), try to decode it.
          if (argsMap['components'] is String) {
            try {
              argsMap['components'] = jsonDecode(
                argsMap['components'] as String,
              );
            } catch (e) {
              print('Failed to decode components string: $e');
            }
          }

          final toolCall = ToolCall(name: name, args: argsMap);
          // Safely attempt parsing
          try {
            final parsed = parseToolCall(toolCall, name);
            for (final msg in parsed.messages) {
              _a2uiMessageController.add(msg);
            }
          } catch (e) {
            print('Error parsing tool call to A2UI messages: $e');
            print('Faulty Args: $argsMap');
          }
        }
      }
    } catch (e) {
      print('Error iterating toolCalls: $e');
    }
  }

  Future<void> _processContent(
    String content,
    List<Map<String, Object?>> historyMessages,
  ) async {
    // 1. Send the full text response first
    // Remove the tool call XML from the text response
    final cleanContent = content
        .replaceAll(
          RegExp(r'<minimax:tool_call>[\s\S]*?</minimax:tool_call>'),
          '',
        )
        .trim();
    if (cleanContent.isNotEmpty) {
      _textResponseController.add(cleanContent);
    }

    // 2. Parse for DSL blocks (Standard method)
    final dslPattern = RegExp(
      r'```(dsl|web)\s*\n([\s\S]*?)```',
      multiLine: true,
    );
    for (final match in dslPattern.allMatches(content)) {
      final language = match.group(1);
      final jsonString = match.group(2)?.trim();
      if (jsonString != null && jsonString.isNotEmpty && language == 'dsl') {
        _sendSurfaceUpdateFromJson(jsonString);
      }
    }

    // 3. Parse for XML Tool Calls and Loop
    final toolCallPattern = RegExp(
      r'<minimax:tool_call>([\s\S]*?)</minimax:tool_call>',
      multiLine: true,
    );

    // Check if we found any tool calls
    final matches = toolCallPattern.allMatches(content);
    if (matches.isNotEmpty) {
      // We only process the first block of tool calls for simplicity in this loop
      final match = matches.first;
      final innerContent = match.group(1);
      if (innerContent != null) {
        final invokePattern = RegExp(
          r'<invoke name="(.*?)">([\s\S]*?)</invoke>',
          multiLine: true,
        );

        bool hasToolCalls = false;
        final currentHistory = List<Map<String, Object?>>.from(historyMessages);

        // Append the assistant's message with the tool call
        currentHistory.add({'role': 'assistant', 'content': content});

        for (final invokeMatch in invokePattern.allMatches(innerContent)) {
          final toolName = invokeMatch.group(1);

          if (toolName != null) {
            hasToolCalls = true;
            final toolResult = await _executeMockTool(toolName);

            // Append tool result as a user message (robust way for many models)
            currentHistory.add({
              'role': 'user',
              'content': 'Tool `$toolName` returned result:\n$toolResult',
            });
          }
        }

        if (hasToolCalls) {
          // Recursive call to get the next step (Logic to Generate UI)
          await _sendFollowUpRequest(currentHistory);
        }
      }
    }
  }

  Future<String> _executeMockTool(String name) async {
    // Simulate data fetching
    if (name == 'get_portfolio') {
      return jsonEncode({
        'total_value': 1250000.00,
        'positions': [
          {'symbol': 'AAPL', 'amount': 150000, 'pl': '+12%'},
          {'symbol': 'NVDA', 'amount': 200000, 'pl': '+45%'},
          {'symbol': 'GOOGL', 'amount': 100000, 'pl': '-5%'},
        ],
        'risk_level': 'High',
        'sector_allocation': {
          'Technology': '80%',
          'Healthcare': '10%',
          'Cash': '10%',
        },
      });
    } else if (name == 'analyze_risk') {
      return jsonEncode({
        'assessment': 'High Risk',
        'score': 85,
        'warnings': ['Concentrated in Technology sector', 'High volatility'],
        'suggestions': ['Diversify into Bonds', 'Reduce leverage'],
      });
    }
    return '{"status": "ok", "message": "Tool executed (mock)"}';
  }

  Future<void> _sendFollowUpRequest(List<Map<String, Object?>> messages) async {
    try {
      final requestBody = {
        'model': model,
        'messages': messages,
        'stream': false,
        'temperature': 0.7,
      };

      if (catalog != null) {
        final toolDecl = catalogToFunctionDeclaration(
          catalog!,
          'uiGenerationTool',
          'Generates Flutter UI based on user requests.',
        );
        requestBody['tools'] = [
          {'type': 'function', 'function': toolDecl.toJson()},
        ];
      }

      // Log follow-up request details
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('DEBUG: Sending Follow-up Request');
      debugPrint('Model: $model');
      debugPrint('Messages count: ${messages.length}');
      debugPrint(
        'Tools: ${requestBody['tools'] != null ? "enabled" : "disabled"}',
      );
      debugPrint('───────────────────────────────────────────────────────');
      debugPrint('Follow-up Request Body:');
      _printLongString(const JsonEncoder.withIndent('  ').convert(requestBody));
      debugPrint('═══════════════════════════════════════════════════════');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final bodyString = utf8.decode(response.bodyBytes);
        print('DEBUG: Raw Response: $bodyString');

        final data = jsonDecode(bodyString);
        final choice = data['choices'][0];
        final messageData = choice['message'];

        final content = messageData['content'];
        if (content != null && content is String && content.isNotEmpty) {
          await _processContent(content, messages);
        }

        final toolCallsRaw = messageData['tool_calls'];
        if (toolCallsRaw != null) {
          if (toolCallsRaw is List) {
            _handleStandardToolCalls(toolCallsRaw);
          } else {
            print(
              'WARNING (FollowUp): tool_calls is not a List, it is ${toolCallsRaw.runtimeType}',
            );
          }
        }
      }
    } catch (e) {
      print('Error in follow-up request: $e');
    }
  }

  void _sendSurfaceUpdateFromJson(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final surfaceId = _uuid.v4();
      _sendSurfaceUpdate(surfaceId, decoded);
    } catch (e) {
      print('Error parsing DSL block from LLM: $e');
    }
  }

  void _sendSurfaceUpdate(
    String surfaceId,
    Map<String, dynamic> componentData,
  ) {
    // Send SurfaceUpdate and BeginRendering
    _a2uiMessageController.add(
      SurfaceUpdate(
        surfaceId: surfaceId,
        components: [Component(id: 'root', componentProperties: componentData)],
      ),
    );
    _a2uiMessageController.add(
      BeginRendering(surfaceId: surfaceId, root: 'root'),
    );
  }

  /// Helper method to print long strings without truncation.
  void _printLongString(String text) {
    final pattern = RegExp('.{1,800}'); // Split every 800 characters
    pattern.allMatches(text).forEach((match) {
      debugPrint(match.group(0));
    });
  }

  @override
  void dispose() {
    _a2uiMessageController.close();
    _textResponseController.close();
    _errorController.close();
    _isProcessing.dispose();
  }
}
