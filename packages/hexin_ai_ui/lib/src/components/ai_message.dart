// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:http/http.dart' as http;
import 'package:json_schema_builder/json_schema_builder.dart';

/// Base URL for the AI flow API (configurable)
const String _defaultFlowApiBaseUrl = 'https://cs.cnht.com.cn:9443';

/// Schema for AI message component.
///
/// DSL Example:
/// ```json
/// {
///   "type": "ai_message",
///   "props": {
///     "info": "截至09:28的股市焦点",
///     "timestamp": "1770089370780",
///     "detail": "展开展示截止09:28AI总结分析的股市重点内容...",
///     "name": "aimi",
///     "avatar": "assets/aimi.png",
///     "expandable": true
///   }
/// }
/// ```
final _aiMessageSchema = S.object(
  description: 'AI 助手消息气泡，显示 AI 生成的简短信息，支持展开查看详情',
  properties: {
    'info': S.string(description: 'AI 消息内容（简短摘要）'),
    'timestamp': S.string(description: '时间戳，用于请求详情'),
    'detail': S.string(description: '展开后显示的详细内容（可选，静态内容）'),
    'avatar': S.string(description: '头像 URL 或 asset 路径（可选）'),
    'name': S.string(description: 'AI 助手名称（可选，默认为 aimi）'),
    'expandable': S.boolean(description: '是否可展开（可选，默认 false）'),
    'defaultExpanded': S.boolean(description: '默认是否展开（可选，默认 false）'),
    'flowApiBaseUrl': S.string(description: 'API 基础地址（可选）'),
  },
  required: ['info'],
);

/// AI message bubble component.
///
/// Displays an AI assistant message with avatar and info text.
/// Supports expandable detail content with API fetch on click.
final aiMessage = CatalogItem(
  name: 'ai_message',
  dataSchema: _aiMessageSchema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "ai_message": {
              "info": "为您提炼了截止09:28的股市重点",
              "name": "aimi"
            }
          }
        }
      ]
    ''',
    () => '''
      [
        {
          "id": "root",
          "component": {
            "ai_message": {
              "info": "为您提炼了截止09:28的股市重点",
              "timestamp": "1770089370780",
              "name": "aimi",
              "expandable": true
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final String info = data['info'] as String? ?? '';
    final String? timestamp = data['timestamp'] as String?;
    final String? detail = data['detail'] as String?;
    final String? avatar = data['avatar'] as String?;
    final String name = data['name'] as String? ?? 'aimi';
    final bool expandable = data['expandable'] as bool? ?? (detail != null);
    final bool defaultExpanded = data['defaultExpanded'] as bool? ?? false;
    final String flowApiBaseUrl =
        data['flowApiBaseUrl'] as String? ?? _defaultFlowApiBaseUrl;

    return _AiMessageBubble(
      info: info,
      timestamp: timestamp,
      detail: detail,
      avatar: avatar,
      name: name,
      expandable: expandable,
      defaultExpanded: defaultExpanded,
      flowApiBaseUrl: flowApiBaseUrl,
    );
  },
);

class _AiMessageBubble extends StatefulWidget {
  const _AiMessageBubble({
    required this.info,
    this.timestamp,
    this.detail,
    this.avatar,
    required this.name,
    this.expandable = true,
    this.defaultExpanded = false,
    required this.flowApiBaseUrl,
  });

  final String info;
  final String? timestamp;
  final String? detail;
  final String? avatar;
  final String name;
  final bool expandable;
  final bool defaultExpanded;
  final String flowApiBaseUrl;

  @override
  State<_AiMessageBubble> createState() => _AiMessageBubbleState();
}

class _AiMessageBubbleState extends State<_AiMessageBubble>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  // API response state
  bool _isLoading = false;
  String? _responseText;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.defaultExpanded;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
        // Fetch detail when expanding if timestamp is provided
        if (widget.timestamp != null) {
          _fetchDetail();
        }
      } else {
        _animationController.reverse();
      }
    });
  }

  /// Fetch detail content from the flow API
  Future<void> _fetchDetail() async {
    if (widget.timestamp == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = Uri.parse(
        '${widget.flowApiBaseUrl}/agent/flow/v2/run_by_flux',
      );
      final body = jsonEncode({
        'expire': 86400,
        'inputVariableValue': {'timestamp': widget.timestamp},
        'flowId': 27063,
        'mode': 'WORK_FLOW',
      });

      debugPrint('AI Message requesting: $url');
      debugPrint('AI Message body: $body');

      final response = await http.post(
        url,
        headers: {
          'businessType': 'ai-app2.0',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      debugPrint('AI Message response status: ${response.statusCode}');
      debugPrint('AI Message response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        // Parse SSE response - extract text from respond events
        final text = _parseSSEResponse(response.body);
        if (mounted) {
          setState(() {
            _responseText = text;
            _isLoading = false;
          });
        }
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      debugPrint('AI Message error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = '加载失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Parse SSE response and extract the final text content
  String _parseSSEResponse(String responseBody) {
    final lines = responseBody.split('\n');
    String? lastText;

    for (final line in lines) {
      if (!line.startsWith('data:')) continue;

      final jsonStr = line.substring(5).trim();
      if (jsonStr.isEmpty) continue;

      try {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        final innerData = data['data'] as Map<String, dynamic>?;
        if (innerData == null) continue;

        // Check for result.text in the response
        final result = innerData['result'];
        if (result is Map<String, dynamic>) {
          final text = result['text'] as String?;
          if (text != null && text.isNotEmpty) {
            lastText = text;
          }

          // Also check for output field (from branch merge)
          final output = result['output'] as String?;
          if (output != null && output.isNotEmpty) {
            lastText = output;
          }
        }
      } catch (e) {
        // Skip invalid JSON lines
        continue;
      }
    }

    return lastText ?? '暂无详情内容';
  }

  @override
  Widget build(BuildContext context) {
    // Always use expandable version
    return _buildExpandableMessage();
  }

  /// Simple non-expandable message (blue bubble with opacity)
  Widget _buildSimpleMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2B7EFF).withOpacity(0.16),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildAvatar(size: 26),
          const SizedBox(width: 8),
          Flexible(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'PingFangSC',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: '${widget.name} ',
                    style: const TextStyle(color: Color(0xFF408BEC)),
                  ),
                  TextSpan(
                    text: widget.info,
                    style: const TextStyle(color: Color(0xFFFFFFFF)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the content to display in the expanded area
  Widget _buildExpandedContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white70,
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Text(
        _errorMessage!,
        style: TextStyle(
          fontFamily: 'PingFangSC',
          fontWeight: FontWeight.w400,
          fontSize: 14,
          color: Colors.red.withOpacity(0.85),
          height: 1.5,
        ),
      );
    }

    // Priority: API response > static detail > placeholder
    final displayText = _responseText ?? widget.detail ?? '请求待实现';

    return Text(
      displayText,
      style: TextStyle(
        fontFamily: 'PingFangSC',
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: Colors.white.withOpacity(0.85),
        height: 1.5,
      ),
    );
  }

  /// Expandable message (blue background with expand/collapse)
  Widget _buildExpandableMessage() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2B7EFF).withOpacity(0.16),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row with avatar, name, info, and expand button
          InkWell(
            onTap: _toggleExpand,
            borderRadius: BorderRadius.circular(19),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildAvatar(size: 26),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      maxLines: _isExpanded ? null : 1,
                      overflow: _isExpanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'PingFangSC',
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: '${widget.name} ',
                            style: const TextStyle(color: Color(0xFF408BEC)),
                          ),
                          TextSpan(
                            text: widget.info,
                            style: const TextStyle(color: Color(0xFFFFFFFF)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Expand/Collapse icon
                  RotationTransition(
                    turns: Tween(
                      begin: 0.0,
                      end: 0.5,
                    ).animate(_expandAnimation),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white.withOpacity(0.7),
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expanded content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _buildExpandedContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar({double size = 28, Color bgColor = Colors.white}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: widget.avatar != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(size / 2),
              child: Image.asset(
                widget.avatar!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultAvatarIcon(size),
              ),
            )
          : _buildDefaultAvatarIcon(size),
    );
  }

  Widget _buildDefaultAvatarIcon(double size) {
    return Center(
      child: Text(
        widget.name.isNotEmpty ? widget.name[0].toUpperCase() : 'A',
        style: TextStyle(
          color: const Color(0xFFFF8C00),
          fontWeight: FontWeight.bold,
          fontSize: size * 0.5,
        ),
      ),
    );
  }
}
