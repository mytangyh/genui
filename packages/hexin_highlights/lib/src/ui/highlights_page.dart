// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:hexin_dsl/hexin_dsl.dart';

import '../catalog/highlights_catalog.dart';
import '../models/highlights_response.dart';
import '../services/highlights_service.dart';

/// Page displaying real-time financial highlights and news.
/// Supports pull-to-refresh and scroll-to-latest button.
class HighlightsPage extends StatefulWidget {
  const HighlightsPage({super.key});

  @override
  State<HighlightsPage> createState() => _HighlightsPageState();
}

class _HighlightsPageState extends State<HighlightsPage>
    with AutomaticKeepAliveClientMixin {
  final HighlightsService _service = HighlightsService(useMockData: false);
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  String? _errorMessage;

  // Items stored in descending order [New...Old] for reverse list display
  final List<NewsSummary> _items = [];

  // Track if user has scrolled away from bottom (latest)
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _initLoad();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // With reverse: true:
    // - pixels == 0 means at visual BOTTOM (newest items)
    // - pixels > 0 means scrolled up to view older items

    if (_scrollController.hasClients) {
      final showButton = _scrollController.position.pixels > 200;
      if (showButton != _showScrollToBottom) {
        setState(() => _showScrollToBottom = showButton);
      }

      // Load history when near the top (oldest items)
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadHistory();
      }
    }
  }

  void _scrollToLatest() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Initial Load (Latest 30 items)
  Future<void> _initLoad() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _service.fetchHighlights(limit: 30);

      // Fetch questions separately
      List<String> questions = [];
      try {
        questions = await _service.fetchQuestions();
      } catch (e) {
        debugPrint('Failed to fetch questions: $e');
      }

      if (mounted) {
        setState(() {
          _items.clear();

          List<NewsSummary> summaries =
              response.data.summaries.reversed.toList();

          // Inject "People Also Ask" card if we have questions and data
          if (questions.isNotEmpty && summaries.isNotEmpty) {
            final newestItem = summaries.first;
            final newestTime = int.tryParse(newestItem.updateTime) ??
                DateTime.now().millisecondsSinceEpoch;
            final fakeTime = newestTime + 1000;

            final questionObjects = questions
                .map((q) => {
                      'text': q,
                      'route':
                          'client://ai.route/question?q=${Uri.encodeComponent(q)}'
                    })
                .toList();

            final cardJson = {
              'type': 'peopleAlsoAskCard',
              'props': {
                'title': '大家还在问',
                'avatarUrl':
                    'http://u.thsi.cn/imgsrc/passport/92224443/head_120.jpg',
                'questions': questionObjects,
              }
            };

            // Manually construct markdown with embedded DSL
            final markdown = '```dsl\n${jsonEncode(cardJson)}\n```';

            final cardSummary = NewsSummary(
              markDown: markdown,
              updateTime: fakeTime.toString(),
            );

            // Insert at beginning (Bottom of reverse list)
            summaries.insert(0, cardSummary);
          }

          _items.addAll(summaries);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Pull-to-refresh: reload latest data
  Future<void> _onRefresh() async {
    try {
      final response = await _service.fetchHighlights(limit: 30);

      // Fetch questions separately
      List<String> questions = [];
      try {
        questions = await _service.fetchQuestions();
      } catch (e) {
        debugPrint('Failed to fetch questions: $e');
      }

      if (mounted) {
        setState(() {
          _items.clear();
          List<NewsSummary> summaries =
              response.data.summaries.reversed.toList();

          // Inject "People Also Ask" card logic (duplicate for now to ensure consistency)
          if (questions.isNotEmpty && summaries.isNotEmpty) {
            final newestItem = summaries.first;
            final newestTime = int.tryParse(newestItem.updateTime) ??
                DateTime.now().millisecondsSinceEpoch;
            final fakeTime = newestTime + 1000;

            final questionObjects = questions
                .map((q) => {
                      'text': q,
                      'route':
                          'client://ai.route/question?q=${Uri.encodeComponent(q)}'
                    })
                .toList();

            final cardJson = {
              'type': 'peopleAlsoAskCard',
              'props': {
                'title': '大家还在问',
                'avatarUrl':
                    'http://u.thsi.cn/imgsrc/passport/92224443/head_120.jpg',
                'questions': questionObjects,
              }
            };

            final markdown = '```dsl\n${jsonEncode(cardJson)}\n```';

            final cardSummary = NewsSummary(
              markDown: markdown,
              updateTime: fakeTime.toString(),
            );

            summaries.insert(0, cardSummary);
          }

          _items.addAll(summaries);
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnack('刷新失败: $e');
      }
    }
  }

  // Load History (scroll to visual top = oldest items)
  bool _isLoadingHistory = false;

  Future<void> _loadHistory() async {
    if (_isLoadingHistory || _isLoading || _items.isEmpty) return;

    // Find oldest item (last in _items since it's descending [New...Old])
    final oldestItem = _items.last;
    final oldestTime = int.parse(oldestItem.updateTime);

    _isLoadingHistory = true;

    try {
      final response = await _service.fetchHighlights(
        endTime: oldestTime,
        limit: 30,
      );

      if (!mounted) return;

      final historyItems = response.data.summaries; // Ascending [Older...Old]

      if (historyItems.isNotEmpty) {
        setState(() {
          // Add older items to end (reverse since we need [New...Old] order)
          _items.addAll(historyItems.reversed);
        });
      }
    } catch (e) {
      // Silently ignore history load errors
    } finally {
      _isLoadingHistory = false;
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _handleAction(String actionName, Map<String, dynamic> actionContext) {
    if (actionName == 'link_tap') {
      // Handle link
    }
    final snackBar = SnackBar(
      content: Text('Action: $actionName, Context: $actionContext'),
      behavior: SnackBarBehavior.floating,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFF191919),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        backgroundColor: const Color(0xFF1E2A3D),
        color: const Color(0xFFFF8C00),
        child: _buildContent(),
      ),
      floatingActionButton: _showScrollToBottom
          ? FloatingActionButton(
              mini: true,
              backgroundColor: const Color(0xFF2A2A35),
              onPressed: _scrollToLatest,
              child: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFFFF8C00),
              ),
            )
          : null,
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF8C00)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initLoad,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C00),
              ),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: Text('暂无数据', style: TextStyle(color: Colors.white54)),
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      reverse: true, // Start from bottom, newest items at visual bottom
      slivers: [
        // Main content
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= _items.length) {
                if (_isLoadingHistory) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFF8C00),
                        ),
                      ),
                    ),
                  );
                }
                return null;
              }
              final item = _items[index];
              return _buildTimelineSection(
                DslMarkdownSection(
                  markdown: item.markDown,
                  catalog: HighlightsCatalog.getCatalog(),
                  onAction: _handleAction,
                ),
              );
            },
            childCount: _items.length + (_isLoadingHistory ? 1 : 0),
          ),
        ),
      ],
    );
  }

  /// Builds a section with timeline decoration.
  Widget _buildTimelineSection(Widget content) {
    return Stack(
      children: [
        // Timeline - vertical dashed line at 14dp from left
        Positioned(
          left: 14,
          top: 0,
          bottom: 0,
          child: CustomPaint(
            painter: _DashedLinePainter(
              color: Colors.white.withOpacity(0.2),
            ),
            size: const Size(1, double.infinity),
          ),
        ),

        // Content with proper margins
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 13),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              content,
              // Blue dot indicator on the timeline
              Positioned(
                left: -13,
                top: 18,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2B7EFF),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom painter for dashed vertical line.
class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashHeight = 4.0;
    const dashSpace = 4.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
