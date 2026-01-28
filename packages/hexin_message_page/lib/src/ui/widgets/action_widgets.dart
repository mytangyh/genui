// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// A summary action button for AI summary activation.
class AiSummaryButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;

  const AiSummaryButton({
    super.key,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2B7EFF), Color(0xFF6C5CE7)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              const Text(
                '🐾',
                style: TextStyle(fontSize: 14),
              ),
            const SizedBox(width: 8),
            Text(
              isLoading ? '正在生成...' : '未读消息AI总结',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A standard button for AI actions like "Mark as Read".
class AiActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const AiActionButton({
    super.key,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF2B7EFF)),
          borderRadius: BorderRadius.circular(20),
          color: Colors.transparent,
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF2B7EFF),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Full-width action button for prompts if needed.
class AiPromptButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const AiPromptButton({
    super.key,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2B7EFF), Color(0xFF6C5CE7)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
