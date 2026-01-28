// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Data models for message-related functionality.

/// Represents a message forum/category.
class MessageForum {
  final String id;
  final String fid;
  final String fname;
  final String? desc;
  final String? path;
  final int number;
  final String? curNoReadMsgId;
  final String? curNoReadMsgTitle;
  final String? curNoReadMsgCreateTime;

  MessageForum({
    required this.id,
    required this.fid,
    required this.fname,
    this.desc,
    this.path,
    this.number = 0,
    this.curNoReadMsgId,
    this.curNoReadMsgTitle,
    this.curNoReadMsgCreateTime,
  });

  factory MessageForum.fromJson(Map<String, dynamic> json) {
    return MessageForum(
      id: json['id'] as String? ?? '',
      fid: json['fid'] as String? ?? '',
      fname: json['fname'] as String? ?? '',
      desc: json['desc'] as String?,
      path: json['path'] as String?,
      number: json['number'] as int? ?? 0,
      curNoReadMsgId: json['curNoReadMsgId'] as String?,
      curNoReadMsgTitle: json['curNoReadMsgTitle'] as String?,
      curNoReadMsgCreateTime: json['curNoReadMsgCreateTime'] as String?,
    );
  }
}

/// Represents a single message item.
class MessageItem {
  final String msgid;
  final String? title;
  final String? intro;
  final String? content;
  final String? forum;
  final int createtime;
  final int read;
  final String? author;
  final String? source;

  MessageItem({
    required this.msgid,
    this.title,
    this.intro,
    this.content,
    this.forum,
    this.createtime = 0,
    this.read = 0,
    this.author,
    this.source,
  });

  factory MessageItem.fromJson(Map<String, dynamic> json) {
    return MessageItem(
      msgid: json['msgid'] as String? ?? '',
      title: json['title'] as String?,
      intro: json['intro'] as String?,
      content: json['content'] as String?,
      forum: json['forum'] as String?,
      createtime: json['createtime'] as int? ?? 0,
      read: json['read'] as int? ?? 0,
      author: json['author'] as String?,
      source: json['source'] as String?,
    );
  }

  bool get isRead => read == 1;

  DateTime get createDateTime =>
      DateTime.fromMillisecondsSinceEpoch(createtime);
}

/// Represents an AI summary of messages.
class AiSummary {
  final int time;
  final String content;
  final String? text;

  AiSummary({
    required this.time,
    required this.content,
    this.text,
  });

  factory AiSummary.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as String? ?? '';
    String? text;

    // Try to parse nested JSON structure
    try {
      if (content.isNotEmpty) {
        // The content is already a JSON string, parse result.text from it
        final decoded = _parseNestedJson(content);
        text = decoded;
      }
    } catch (_) {
      text = content;
    }

    return AiSummary(
      time: json['time'] as int? ?? 0,
      content: content,
      text: text,
    );
  }

  DateTime get createDateTime => DateTime.fromMillisecondsSinceEpoch(time);

  static String? _parseNestedJson(String jsonStr) {
    try {
      // Remove escape sequences and parse
      final cleaned = jsonStr
          .replaceAll(r'\\n', '\n')
          .replaceAll(r'\\', '')
          .replaceAll(r'\"', '"');

      // Find the text field in the result
      final textMatch =
          RegExp(r'"text"\s*:\s*"([^"]*(?:\\"[^"]*)*)"').firstMatch(cleaned);
      if (textMatch != null) {
        return textMatch.group(1)?.replaceAll(r'\n', '\n');
      }
      return cleaned;
    } catch (_) {
      return jsonStr;
    }
  }
}
