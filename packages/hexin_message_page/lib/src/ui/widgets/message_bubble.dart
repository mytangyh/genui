// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// A single message bubble widget for displaying AI messages.
/// A single message bubble widget for displaying AI messages or simulated user messages.
class MessageBubble extends StatelessWidget {
  final String avatarUrl;
  final String senderName;
  final String message;
  final Widget? actionWidget;
  final VoidCallback? onTap;
  final bool isRead;
  final int maxLines;
  final bool showArrow;
  final bool isUser;

  const MessageBubble({
    super.key,
    this.avatarUrl = '',
    this.senderName = 'Aimi',
    required this.message,
    this.actionWidget,
    this.onTap,
    this.isRead = false,
    this.maxLines = 0,
    this.showArrow = true,
    this.isUser = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  senderName,
                  style: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 8),
                _buildAvatar(),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2B7EFF), Color(0xFF6C5CE7)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // AI Message Style
    final textColor =
        isRead ? const Color(0xFF999999) : const Color(0xFFE1E1E1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 8),
              Text(
                senderName,
                style: const TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: _buildMessageContent(textColor),
          ),
          if (actionWidget != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: actionWidget,
            ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(Color textColor) {
    // If maxLines is set, use Text with overflow and Row for arrow
    if (maxLines > 0) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              message,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
          if (showArrow && actionWidget == null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF333344),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: const Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: Color(0xFF2B7EFF),
                ),
              ),
            ),
        ],
      );
    }

    // Use Markdown for unlimited lines (AI summary content)
    // AI Message Style - Use MarkdownBody
    return MarkdownBody(
      data: message,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          color: textColor,
          fontSize: 15,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    // Use a placeholder dog avatar for Aimi
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFFF8C00),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: avatarUrl.isNotEmpty
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
              )
            : _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return const Center(
      child: Text(
        '🐕',
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}
