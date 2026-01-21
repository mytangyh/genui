// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Data models for the news aggregations API response.

/// Root response from the news aggregations API.
class HighlightsResponse {
  HighlightsResponse({
    required this.flag,
    required this.msg,
    required this.data,
  });

  factory HighlightsResponse.fromJson(Map<String, dynamic> json) {
    return HighlightsResponse(
      flag: json['flag'] as int,
      msg: json['msg'] as String,
      data: HighlightsData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  /// Response status flag (0 = success).
  final int flag;

  /// Response message.
  final String msg;

  /// Response data containing summaries.
  final HighlightsData data;

  Map<String, dynamic> toJson() {
    return {'flag': flag, 'msg': msg, 'data': data.toJson()};
  }
}

/// Data section of the highlights response.
class HighlightsData {
  HighlightsData({required this.summaries, required this.total});

  factory HighlightsData.fromJson(Map<String, dynamic> json) {
    final summariesJson = json['summaries'] as List<dynamic>;
    final summaries = summariesJson
        .map((e) => NewsSummary.fromJson(e as Map<String, dynamic>))
        .toList();

    return HighlightsData(summaries: summaries, total: json['total'] as int);
  }

  /// List of news summaries with embedded DSL markdown.
  final List<NewsSummary> summaries;

  /// Total count of summaries.
  final int total;

  Map<String, dynamic> toJson() {
    return {
      'summaries': summaries.map((e) => e.toJson()).toList(),
      'total': total,
    };
  }
}

/// Individual news summary containing markdown with DSL blocks.
class NewsSummary {
  NewsSummary({required this.markDown, required this.updateTime});

  factory NewsSummary.fromJson(Map<String, dynamic> json) {
    return NewsSummary(
      markDown: json['markDown'] as String,
      updateTime: json['updateTime'] as String,
    );
  }

  /// Markdown content containing DSL code blocks.
  final String markDown;

  /// Update timestamp (epoch milliseconds as string).
  final String updateTime;

  Map<String, dynamic> toJson() {
    return {'markDown': markDown, 'updateTime': updateTime};
  }
}
