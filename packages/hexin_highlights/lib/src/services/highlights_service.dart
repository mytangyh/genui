// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/highlights_response.dart';

/// Service for fetching news aggregations from the API.
///
/// Currently using mock data until the API endpoint is accessible.
class HighlightsService {
  HighlightsService({
    this.baseUrl =
        'https://mncg-base-b2b-cloud.0033.com/simulated-stocks-web-saas/ai/info/api/news/aggregations',
    this.useMockData = false,
  });

  /// Base URL for the news aggregations API.
  final String baseUrl;

  /// Whether to use mock data instead of real API calls.
  final bool useMockData;

  /// Fetches news aggregations with optional time range and limit.
  ///
  /// [startTime] - Optional start time filter (epoch milliseconds).
  /// [endTime] - Optional end time filter (epoch milliseconds).
  /// [limit] - Maximum number of results to return (default: 30).
  ///
  /// Returns a [HighlightsResponse] containing the news summaries.
  /// Throws an [Exception] if the request fails or returns an error.
  Future<HighlightsResponse> fetchHighlights({
    int? startTime,
    int? endTime,
    int limit = 30,
  }) async {
    // Use mock data if enabled
    if (useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 500));

      var summaries = List<Map<String, dynamic>>.from(
        (_mockData['data']['summaries'] as List).cast<Map<String, dynamic>>(),
      );

      // Parse dates for filtering
      // Timestamps in mock data are string epoch milliseconds.

      // Filter by startTime (exclusive - newer than this)
      if (startTime != null) {
        summaries = summaries.where((s) {
          final time = int.tryParse(s['updateTime'] as String) ?? 0;
          return time > startTime;
        }).toList();
      }

      // Filter by endTime (exclusive - older than this)
      if (endTime != null) {
        summaries = summaries.where((s) {
          final time = int.tryParse(s['updateTime'] as String) ?? 0;
          return time < endTime;
        }).toList();
      }

      // Sort by time descending (newest first) as usually expected in data layer
      summaries.sort((a, b) {
        final timeA = int.tryParse(a['updateTime'] as String) ?? 0;
        final timeB = int.tryParse(b['updateTime'] as String) ?? 0;
        return timeB.compareTo(timeA); // Descending
      });

      final total = summaries.length;

      // Apply limit
      if (summaries.length > limit) {
        summaries = summaries.take(limit).toList();
      }

      // According to requirement: "response list is ascending"
      // So we reverse the result before returning using logical timeline order
      summaries = summaries.reversed.toList();

      return HighlightsResponse.fromJson({
        "flag": 0,
        "msg": "成功",
        "data": {
          "summaries": summaries,
          "total": total,
        }
      });
    }

    try {
      final requestBody = {
        'startTime': startTime,
        'endTime': endTime,
        'limit': limit,
      };

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch highlights: HTTP ${response.statusCode}',
        );
      }

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      final highlightsResponse = HighlightsResponse.fromJson(jsonData);

      if (highlightsResponse.flag != 0) {
        throw Exception('API error: ${highlightsResponse.msg}');
      }

      return highlightsResponse;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to fetch highlights: $e');
    }
  }

  // Mock data for development
  static final Map<String, dynamic> _mockData = {
    "flag": 0,
    "msg": "成功",
    "data": {
      "summaries": _generateMockItems(),
      "total": 60,
    },
  };

  static List<Map<String, dynamic>> _generateMockItems() {
    // Generate 60 items with differing timestamps
    final baseTime = 1768966371581; // 2026 approx
    return List.generate(60, (index) {
      // Index 0 is newest
      final time = baseTime - (index * 600000); // 10 minutes apart
      return {
        "markDown": '''```dsl
{"simplyDSL":"1","children":[{"type":"targetHeader","props":{"targetName":"Mock Item $index","trend":"${index % 2 == 0 ? 'up' : 'down'}","targetValue":"4000.00  +0.00%","title":"Test","timestamp":"$time"}}]}
```
### Mock News Item $index
This is a generated news item for testing pagination. Index: $index. Time: $time.
''',
        "updateTime": "$time",
      };
    });
  }
}
