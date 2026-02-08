// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'market_data_service.dart';

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

  /// 数据 Tools 定义（用于获取真实数据）
  static final List<Map<String, Object?>> _dataTools = [
    {
      'type': 'function',
      'function': {
        'name': 'get_market_overview',
        'description': '获取大盘实时行情概况，包括上证指数、深证成指、创业板指的实时数据和市场情绪。'
            '返回真实新浪财经数据。当用户问"看大盘"、"大盘怎么样"、"今天行情"时调用此工具。',
        'parameters': {'type': 'object', 'properties': {}},
      }
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_realtime_quote',
        'description': '获取单只股票实时行情数据。当用户询问某只股票时调用此工具。',
        'parameters': {
          'type': 'object',
          'properties': {
            'stockCode': {
              'type': 'string',
              'description': '股票代码，如 600519（沪市）或 000001（深市）'
            }
          },
          'required': ['stockCode']
        },
      }
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_morning_brief',
        'description': '获取今日晨报摘要，包括隔夜重要消息、板块异动、北向资金等。盘前场景可用。',
        'parameters': {'type': 'object', 'properties': {}},
      }
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_trading_history',
        'description': '获取用户今日交易记录，包括买入卖出操作、时间、价格等。盘后复盘可用。',
        'parameters': {'type': 'object', 'properties': {}},
      }
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_portfolio',
        'description': '获取用户当前持仓详情，包括股票列表、成本价、当前价、盈亏等。',
        'parameters': {'type': 'object', 'properties': {}},
      }
    },
  ];

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
        final uiToolDecl = catalogToFunctionDeclaration(
          catalog!,
          'uiGenerationTool',
          'Generates Flutter UI based on user requests.',
        );

        tools = [
          {'type': 'function', 'function': uiToolDecl.toJson()},
          // 使用静态配置的数据 Tools
          ..._dataTools,
        ];
      }

      final requestBody = {
        'model': model,
        'messages': messages,
        'stream': false,
        'temperature': 0.7,
        'max_tokens': 16384, // Increased to prevent tool call JSON truncation
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
        // Use _printLongString to avoid truncation
        debugPrint('DEBUG: Raw Response Length: ${bodyString.length}');

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
        debugPrint('DEBUG: tool_calls found: ${toolCallsRaw != null}');
        if (toolCallsRaw != null) {
          if (toolCallsRaw is List) {
            debugPrint('DEBUG: tool_calls count: ${toolCallsRaw.length}');
            await _handleStandardToolCalls(toolCallsRaw, messages);
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

  Future<void> _handleStandardToolCalls(
    List toolCalls,
    List<Map<String, Object?>> currentMessages,
  ) async {
    // 收集需要进行多轮对话的数据 Tools 结果
    final List<Map<String, String>> dataToolResults = [];

    try {
      for (final toolCallJson in toolCalls) {
        if (toolCallJson is! Map) {
          debugPrint('WARNING: toolCallJson is not a Map: $toolCallJson');
          continue;
        }
        final function = toolCallJson['function'];
        if (function == null || function is! Map) continue;

        final name = function['name'] as String?;
        debugPrint('DEBUG: Tool name: $name');
        if (name == null) continue;

        final arguments = function['arguments'];
        debugPrint(
            'DEBUG: Arguments type: ${arguments.runtimeType}, length: ${arguments is String ? arguments.length : "N/A"}');

        // OpenAI format arguments are usually stringified JSON
        Map<String, Object?> argsMap = {};
        try {
          if (arguments is String) {
            final decoded = jsonDecode(arguments);
            if (decoded is Map<String, dynamic>) {
              argsMap = decoded;
              debugPrint('DEBUG: Successfully decoded arguments');
            }
          } else if (arguments is Map) {
            argsMap = Map<String, Object?>.from(arguments);
          }
        } catch (e) {
          debugPrint('ERROR decoding tool arguments: $e');
          debugPrint(
              'Arguments preview: ${arguments is String ? arguments.substring(0, arguments.length > 200 ? 200 : arguments.length) : arguments}');
          continue;
        }

        // 处理数据 Tools（需要多轮对话）
        if (name == 'get_market_overview' || name == 'get_realtime_quote') {
          final toolCallId = toolCallJson['id'] as String? ?? 'unknown';
          debugPrint('📡 DEBUG: Processing data tool: $name, id: $toolCallId');
          final result = await _executeMockTool(name, argsMap);
          debugPrint('📡 DEBUG: Data tool result: ${result.length} chars');
          dataToolResults.add({
            'toolCallId': toolCallId,
            'name': name,
            'result': result,
          });
          continue;
        }

        if (name == 'uiGenerationTool') {
          debugPrint('DEBUG: Processing uiGenerationTool');
          // Heuristic Fix: If 'components' is a string (double-encoded), try to decode it.
          if (argsMap['components'] is String) {
            try {
              // 先尝试修复常见的 JSON 问题
              var componentsStr = argsMap['components'] as String;

              // 修复未转义的换行符
              componentsStr = componentsStr
                  .replaceAll('\n', '\\n')
                  .replaceAll('\r', '\\r')
                  .replaceAll('\t', '\\t');

              argsMap['components'] = jsonDecode(componentsStr);
              debugPrint('DEBUG: Successfully decoded components from string');
            } catch (e) {
              debugPrint('Failed to decode components string: $e');
              debugPrint(
                  'ERROR: Components data is truncated or malformed, skipping this tool call');
              // Skip this tool call if components can't be decoded
              continue;
            }
          }

          debugPrint('DEBUG: argsMap keys: ${argsMap.keys}');
          debugPrint(
              'DEBUG: components type: ${argsMap['components']?.runtimeType}');

          // Log the first component to see what LLM generated
          final components = argsMap['components'] as List?;
          if (components != null && components.isNotEmpty) {
            final firstComp = components.first;
            debugPrint('DEBUG: First component: ${jsonEncode(firstComp)}');
          }

          // Custom message generation instead of parseToolCall
          // This allows setting the correct catalogId
          try {
            final surfaceId =
                argsMap['surfaceId'] as String? ?? 'default_surface';
            debugPrint('DEBUG: Creating messages for surfaceId: $surfaceId');

            // Create SurfaceUpdate message
            final surfaceUpdateJson = {'surfaceUpdate': argsMap};
            final surfaceUpdateMessage =
                A2uiMessage.fromJson(surfaceUpdateJson);

            // Create BeginRendering message with correct catalogId
            final beginRenderingMessage = BeginRendering(
              surfaceId: surfaceId,
              root: 'root',
              catalogId: catalog?.catalogId, // Use the catalog's ID!
            );

            debugPrint(
                'DEBUG: Created messages with catalogId: ${catalog?.catalogId}');
            _a2uiMessageController.add(surfaceUpdateMessage);
            _a2uiMessageController.add(beginRenderingMessage);
            debugPrint('DEBUG: Messages added to stream');
          } catch (e) {
            debugPrint('ERROR creating A2UI messages: $e');
            debugPrint('Faulty Args keys: ${argsMap.keys}');
          }
        }
      }
    } catch (e) {
      debugPrint('ERROR iterating toolCalls: $e');
    }

    // 如果有数据 Tool 结果，进行多轮对话
    if (dataToolResults.isNotEmpty) {
      debugPrint(
          '🔄 DEBUG: Data tools executed (${dataToolResults.length}), triggering follow-up request');

      // 添加 assistant 的 tool_calls 消息
      currentMessages.add({
        'role': 'assistant',
        'tool_calls': toolCalls,
      });

      // 添加每个 Tool 的结果
      for (final result in dataToolResults) {
        currentMessages.add({
          'role': 'tool',
          'tool_call_id': result['toolCallId'],
          'name': result['name'],
          'content': result['result'],
        });
      }

      // 发起第二轮请求
      await _sendFollowUpRequest(currentMessages);
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

  final MarketDataService _marketDataService = MarketDataService();

  Future<String> _executeMockTool(String name,
      [Map<String, Object?>? args]) async {
    // 新增：真实数据 Tools
    if (name == 'get_morning_brief') {
      final data = await _marketDataService.getMorningBrief();
      return jsonEncode(data);
    } else if (name == 'get_news') {
      final news = await _marketDataService.getMarketNews();
      return jsonEncode({'news': news, 'count': news.length});
    } else if (name == 'get_trading_history') {
      final history = await _marketDataService.getTradingHistory();
      return jsonEncode(history);
    } else if (name == 'get_realtime_quote') {
      // 默认返回上证指数
      final quote = await _marketDataService.getRealTimeQuote('sh000001');
      return jsonEncode(quote ?? {'error': '获取行情失败'});
    } else if (name == 'get_market_overview') {
      // 获取三大指数真实数据
      final overview = await _marketDataService.getMarketOverview();
      return jsonEncode(overview);
    }

    // 原有 Mock Tools
    if (name == 'get_portfolio') {
      return jsonEncode({
        'total_value': 500000.00,
        'positions': [
          {
            'symbol': '600519',
            'name': '贵州茅台',
            'shares': 100,
            'cost': 1800,
            'current': 1850,
            'pl': '+2.78%'
          },
          {
            'symbol': '002594',
            'name': '比亚迪',
            'shares': 500,
            'cost': 230,
            'current': 280,
            'pl': '+14.29%'
          },
          {
            'symbol': '601318',
            'name': '中国平安',
            'shares': 200,
            'cost': 45,
            'current': 42,
            'pl': '-6.67%'
          },
        ],
        'cash': 50000,
        'todayPL': 2580,
      });
    } else if (name == 'analyze_risk') {
      return jsonEncode({
        'riskLevel': 'medium',
        'riskScore': 58,
        'volatility': 0.22,
        'diversification': 65,
        'sectorConcentration': {'金融': '35%', '消费': '40%', '新能源': '25%'},
        'suggestions': [
          '建议增加债券类资产配置，降低整体波动性',
          '当前持仓集中在金融和消费板块，可考虑增加科技股',
          '建议设置止损点，控制单只股票最大亏损在10%以内',
        ],
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
            await _handleStandardToolCalls(toolCallsRaw, messages);
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
