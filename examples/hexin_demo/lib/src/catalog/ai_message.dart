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
    this.expandable = true,
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

  /// Expandable message (blue background with expand/collapse)
  Widget _buildExpandableMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
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
            child: widget.detail != null
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151D2B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.detail!,
                        style: TextStyle(
                          fontFamily: 'PingFangSC',
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.85),
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
