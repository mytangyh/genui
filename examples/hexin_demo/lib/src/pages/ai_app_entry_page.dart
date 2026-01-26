// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'ai_app_page.dart';
import 'general_chat_page.dart';

/// Entry page for the AI App demo.
class AiAppEntryPage extends StatelessWidget {
  const AiAppEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const AiAppPage(),
                  ),
                );
              },
              child: const Text('进入 AI App'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const GeneralChatPage(),
                  ),
                );
              },
              child: const Text('通用 Chatbot (Kelivo-lite)'),
            ),
          ],
        ),
      ),
    );
  }
}
