// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Schema for AI message component.
///
/// DSL Example:
/// ```json
/// {
///   "type": "ai_message",
///   "props": {
///     "info": "截至09:28的股市焦点",
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
    'detail': S.string(description: '展开后显示的详细内容（可选）'),
    'avatar': S.string(description: '头像 URL 或 asset 路径（可选）'),
    'name': S.string(description: 'AI 助手名称（可选，默认为 aimi）'),
    'expandable': S.boolean(description: '是否可展开（可选，默认 false）'),
    'defaultExpanded': S.boolean(description: '默认是否展开（可选，默认 false）'),
  },
  required: ['info'],
);

/// AI message bubble component.
///
/// Displays an AI assistant message with avatar and info text.
/// Supports expandable detail content.
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
              "detail": "展开展示截止09:28AI总结分析的股市重点内容展示截止09:28AI总结分析的股市重点内容，展开展示截止09:28AI总结分析。",
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
    final String? detail = data['detail'] as String?;
    final String? avatar = data['avatar'] as String?;
    final String name = data['name'] as String? ?? 'aimi';
    final bool expandable = data['expandable'] as bool? ?? (detail != null);
    final bool defaultExpanded = data['defaultExpanded'] as bool? ?? false;

    return _AiMessageBubble(
      info: info,
      detail: detail,
      avatar: avatar,
      name: name,
      expandable: expandable,
      defaultExpanded: defaultExpanded,
    );
  },
);

class _AiMessageBubble extends StatefulWidget {
  const _AiMessageBubble({
    required this.info,
    this.detail,
    this.avatar,
    required this.name,
    this.expandable = false,
    this.defaultExpanded = false,
  });

  final String info;
  final String? detail;
  final String? avatar;
  final String name;
  final bool expandable;
  final bool defaultExpanded;

  @override
  State<_AiMessageBubble> createState() => _AiMessageBubbleState();
}

class _AiMessageBubbleState extends State<_AiMessageBubble>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

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
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.expandable) {
      return _buildExpandableMessage();
    }
    return _buildSimpleMessage();
  }

  /// Simple non-expandable message (orange bubble)
  Widget _buildSimpleMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8C00), Color(0xFFFF6B00)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8C00).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAvatar(),
          const SizedBox(width: 10),
          Flexible(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: '${widget.name} ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: widget.info),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Expandable message (dark background with expand/collapse)
  Widget _buildExpandableMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with avatar, name, info, and expand button
          InkWell(
            onTap: _toggleExpand,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildAvatar(size: 24, bgColor: const Color(0xFF2D3A4D)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: '${widget.name} ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF8C00),
                            ),
                          ),
                          TextSpan(
                            text: widget.info,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                            ),
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
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expanded content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: widget.detail != null
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151D2B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.detail!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
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
