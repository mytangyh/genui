// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// A widget to display a chat message with Markdown support.
class MarkdownMessageWidget extends StatelessWidget {
  /// Creates a new [MarkdownMessageWidget].
  const MarkdownMessageWidget({
    super.key,
    required this.text,
    required this.icon,
    required this.alignment,
  });

  /// The text content of the message (Markdown).
  final String text;

  /// The icon to display next to the message.
  final IconData icon;

  /// The alignment of the message.
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final isStart = alignment == MainAxisAlignment.start;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: alignment,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(
                    alignment == MainAxisAlignment.start ? 5 : 25,
                  ),
                  topRight: Radius.circular(
                    alignment == MainAxisAlignment.start ? 25 : 5,
                  ),
                  bottomLeft: const Radius.circular(25),
                  bottomRight: const Radius.circular(25),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isStart) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(icon, size: 20),
                      ),
                      const SizedBox(width: 8.0)
                    ],
                    Flexible(
                      child: MarkdownBody(
                        data: text,
                        styleSheet:
                            MarkdownStyleSheet.fromTheme(Theme.of(context))
                                .copyWith(
                          p: Theme.of(context).textTheme.bodyMedium,
                        ),
                        selectable: true,
                      ),
                    ),
                    if (!isStart) ...[const SizedBox(width: 8.0), Icon(icon)],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
