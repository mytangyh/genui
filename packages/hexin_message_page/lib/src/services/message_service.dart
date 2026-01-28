// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/message_models.dart';

/// Service for fetching message-related data from the API.
class MessageService {
  static const String _baseUrl = 'https://cs.cnht.com.cn:9443';
  static const String _appCode = 'htths';

  final bool useMockData;
  final String phone;

  MessageService({
    this.useMockData = false,
    this.phone = '15254152609',
  });

  /// Fetches the list of message forums/categories.
  Future<List<MessageForum>> fetchForumList() async {
    if (useMockData) {
      return _getMockForumList();
    }

    try {
      debugPrint(
          'Request: ${Uri.parse('$_baseUrl/ai/msgs/infolist')} body: phone=$phone');
      final response = await http.post(
        Uri.parse('$_baseUrl/ai/msgs/infolist'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'phone=$phone',
      );
      debugPrint('Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['r'] == 1) {
          final data = json['data'] as List;
          if (data.isNotEmpty) {
            final cforum = data[0]['cforum'] as List? ?? [];
            return cforum
                .map((e) => MessageForum.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching forum list: $e');
      return [];
    }
  }

  /// Fetches messages, optionally filtered by read status.
  /// [read]: 0 = unread only, -1 = all messages
  Future<List<MessageItem>> fetchMessages({int read = -1}) async {
    if (useMockData) {
      return _getMockMessages();
    }

    try {
      debugPrint(
          'Request: ${Uri.parse('$_baseUrl/ai/msgs/msgList')} body: phone=$phone&read=$read');
      final response = await http.post(
        Uri.parse('$_baseUrl/ai/msgs/msgList'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'phone=$phone&read=$read',
      );
      debugPrint('Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['r'] == 1) {
          final data = json['data'] as List? ?? [];
          return data
              .map((e) => MessageItem.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      return [];
    }
  }

  /// Marks messages as read.
  Future<bool> markAsRead(List<String> msgIds) async {
    if (useMockData) {
      return true;
    }

    try {
      debugPrint(
          'Request: ${Uri.parse('$_baseUrl/ai/msgs/read')} body: phone=$phone&appcode=$_appCode&msgids=${msgIds.join(',')}');
      final response = await http.post(
        Uri.parse('$_baseUrl/ai/msgs/read'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'phone=$phone&appcode=$_appCode&msgids=${msgIds.join(',')}',
      );
      debugPrint('Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['r'] == 1;
      }
      return false;
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
      return false;
    }
  }

  /// Triggers AI summary for unread messages in a forum.
  /// Returns a Stream of text chunks for typewriter effect.
  /// Parses SSE format and extracts text from type:plain messages.
  Stream<String> triggerAiSummaryStream(String forum) async* {
    if (useMockData) {
      // Simulate streaming for mock data
      final mockText = _getMockAiSummaryText();
      for (var i = 0; i < mockText.length; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        yield mockText.substring(0, i + 1);
      }
      return;
    }

    try {
      debugPrint(
          'Request: ${Uri.parse('$_baseUrl/ai/msgs/flow/run_by_flux')} body: phone=$phone&forum=$forum');

      final request = http.Request(
        'POST',
        Uri.parse('$_baseUrl/ai/msgs/flow/run_by_flux'),
      );
      request.headers['Content-Type'] = 'application/x-www-form-urlencoded';
      request.body = 'phone=$phone&forum=$forum';

      final client = http.Client();
      final streamedResponse = await client.send(request);

      debugPrint('Response status: ${streamedResponse.statusCode}');

      if (streamedResponse.statusCode == 200) {
        final textBuffer = StringBuffer();
        final lineBuffer = StringBuffer();

        await for (final chunk
            in streamedResponse.stream.transform(utf8.decoder)) {
          // SSE responses may contain multiple lines in one chunk
          lineBuffer.write(chunk);
          final lines = lineBuffer.toString().split('\n');

          // Process all complete lines (keep the last potentially incomplete one)
          for (var i = 0; i < lines.length - 1; i++) {
            final line = lines[i].trim();
            if (line.startsWith('data:')) {
              final jsonStr = line.substring(5).trim();
              if (jsonStr.isNotEmpty) {
                try {
                  final json = jsonDecode(jsonStr) as Map<String, dynamic>;
                  final type = json['type'] as String?;

                  // Only extract text from type:plain messages
                  if (type == 'plain') {
                    final data = json['data'] as String? ?? '';
                    if (data.isNotEmpty) {
                      textBuffer.write(data);
                      debugPrint('Extracted text: $data');
                      yield textBuffer.toString();
                    }
                  }
                } catch (e) {
                  debugPrint('JSON parse error: $e for line: $jsonStr');
                }
              }
            }
          }

          // Keep the last potentially incomplete line
          lineBuffer.clear();
          lineBuffer.write(lines.last);
        }

        // Process any remaining content
        final remaining = lineBuffer.toString().trim();
        if (remaining.startsWith('data:')) {
          final jsonStr = remaining.substring(5).trim();
          if (jsonStr.isNotEmpty) {
            try {
              final json = jsonDecode(jsonStr) as Map<String, dynamic>;
              if (json['type'] == 'plain') {
                final data = json['data'] as String? ?? '';
                if (data.isNotEmpty) {
                  textBuffer.write(data);
                  yield textBuffer.toString();
                }
              }
            } catch (e) {
              debugPrint('JSON parse error: $e');
            }
          }
        }

        // If no text was extracted, yield a default message
        if (textBuffer.isEmpty) {
          yield '暂无AI总结内容';
        }
      }
      client.close();
    } catch (e) {
      debugPrint('Error triggering AI summary: $e');
      yield 'AI 总结请求失败: $e';
    }
  }

  /// Fetches AI summary history.
  Future<List<AiSummary>> fetchAiHistory({
    required int startTime,
    required int endTime,
  }) async {
    if (useMockData) {
      return _getMockAiHistory();
    }

    try {
      debugPrint(
          'Request: ${Uri.parse('$_baseUrl/ai/msgs/getAgentHistory')} body: phone=$phone&start=$startTime&end=$endTime');
      final response = await http.post(
        Uri.parse('$_baseUrl/ai/msgs/getAgentHistory'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'phone=$phone&start=$startTime&end=$endTime',
      );
      debugPrint('Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List? ?? [];
        return data
            .map((e) => AiSummary.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching AI history: $e');
      return [];
    }
  }

  // ==================== Mock Data ====================

  List<MessageForum> _getMockForumList() {
    return [
      MessageForum(
        id: 'all',
        fid: 'all',
        fname: '全部消息',
        number: 33,
      ),
      MessageForum(
        id: '1006',
        fid: '1006',
        fname: '智能预警',
        desc: '智能盯盘',
        number: 0,
      ),
      MessageForum(
        id: '1002',
        fid: '1002',
        fname: '智能投顾',
        desc: '智能投顾',
        number: 0,
      ),
      MessageForum(
        id: '1009',
        fid: '1009',
        fname: '业务公告',
        desc: '业务公告',
        number: 0,
      ),
      MessageForum(
        id: '1005',
        fid: '1005',
        fname: '账户提醒',
        desc: '账户提醒',
        number: 0,
      ),
    ];
  }

  List<MessageItem> _getMockMessages() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return [
      MessageItem(
        msgid: 'msg_001',
        title: '料连家过变传自么构重原理备干再给走酸领引传大事红',
        intro:
            '料连家过变传自么构重原理备干再给走酸领引传大事红革常况产革办做口转素片高产形研两为包电长件九传群红也图正求消经最细中细世例些得六局从从。根查...',
        content:
            '<p>料连家过变传自么构重原理备干再给走酸领引传大事红革常况产革办做口转素片高产形研两为包电长件九传群红也图正求消经最细中细世例些得六局从从。</p>',
        forum: '1001',
        createtime: now - 86400000 * 5,
        read: 0,
        author: 'Aimi',
      ),
      MessageItem(
        msgid: 'msg_002',
        title: '专更交导干天导感却出因台场数导毛带性定完角却程至',
        intro: '专更交导干天导感却出因台场数导毛带性定完角却程至政省时效地打明各格者派头以必话去备万乙离科部便至半便见慢保。',
        content:
            '<p>专更交导干天导感却出因台场数导毛带性定完角却程至政省时效地打明各格者派头以必话去备万乙离科部便至半便见慢保。</p>',
        forum: '1002',
        createtime: now - 86400000 * 5,
        read: 0,
        author: 'Aimi',
      ),
      MessageItem(
        msgid: 'msg_003',
        title: '子况起重亲走多争片儿具展和往常建义题具会影更八眼',
        intro: '子况起重亲走多争片儿具展和往常建义题具会影更八眼安酸干在国马井那边只子目拉参律我系节理而方格什时太张等期高商眼。',
        content:
            '<p>子况起重亲走多争片儿具展和往常建义题具会影更八眼安酸干在国马井那边只子目拉参律我系节理而方格什时太张等期高商眼。</p>',
        forum: '1003',
        createtime: now - 86400000 * 3,
        read: 0,
        author: 'Aimi',
      ),
      MessageItem(
        msgid: 'msg_004',
        title: '您当前共有33条未读消息，如果需要我帮您总结未读消息的内容概要，请点击',
        intro: '🐾 未读消息AI总结',
        content: '<p>您当前共有33条未读消息，如果需要我帮您总结未读消息的内容概要，请点击 🐾 未读消息AI总结</p>',
        forum: 'system',
        createtime: now - 86400000,
        read: 0,
        author: 'Aimi',
      ),
    ];
  }

  String _getMockAiSummaryText() {
    return '''以对话的形式对未读消息进行AI分析总结，并完整展示AI总结输出的内容。以对话的形式对未读消息进行AI分析总结，并完整展示AI总结输出的内容。''';
  }

  List<AiSummary> _getMockAiHistory() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return [
      AiSummary(
        time: now - 3600000,
        content: '{}',
        text:
            '以对话的形式对未读消息进行AI分析总结，并完整展示AI总结输出的内容。以对话的形式对未读消息进行AI分析总结，并完整展示AI总结输出的内容。',
      ),
    ];
  }
}
