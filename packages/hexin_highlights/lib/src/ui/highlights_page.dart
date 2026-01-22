// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:hexin_dsl/hexin_dsl.dart';

import '../catalog/highlights_catalog.dart';
import '../models/highlights_response.dart';
import '../services/highlights_service.dart';

/// Token representing a gap in the timeline that can be filled.
class GapToken {
  final int startTime; // Newer bound
  final int endTime; // Older bound
  final int remainingCount;

  GapToken({
    required this.startTime,
    required this.endTime,
    required this.remainingCount,
  });
}

/// Page displaying real-time financial highlights and news.
/// Supports infinite scroll, pull-to-refresh, and gap filling.
class HighlightsPage extends StatefulWidget {
  const HighlightsPage({super.key});

  @override
  State<HighlightsPage> createState() => _HighlightsPageState();
}

class _HighlightsPageState extends State<HighlightsPage>
    with AutomaticKeepAliveClientMixin {
  final HighlightsService _service = HighlightsService(useMockData: false);
  final ScrollController _scrollController = ScrollController();
  final Key _centerKey = UniqueKey();

  bool _isLoading = true;
  String? _errorMessage;

  // _headItems: History (Older) items (displayed ABOVE the anchor).
  // Grows UP. Index 0 is closest to anchor (Visual Bottom of Top Sliver).
  // Content: Descending History [Old0, Older1, Older2...].
  // Visual Stack:
  // Older2
  // Older1
  // Old0
  // Anchor (Old1)
  final List<dynamic> _headItems = [];

  // _tailItems: Initial + Newer items (displayed BELOW the anchor).
  // Grows DOWN. Index 0 is anchor.
  // Content: Ascending [Old1, Old2... New30].
  // Old1 (Anchor)
  // Old2
  // ...
  // New30.
  final List<dynamic> _tailItems = [];

  bool _isFetchingMore = false;

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
    // - pixels == maxScrollExtent means at visual TOP (oldest items)

    // Detect scroll to visual top (oldest items) for loading history
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      _loadHistory();
    }

    // Detect scroll to visual bottom (newest items) for loading newer
    if (_scrollController.hasClients &&
        _scrollController.position.pixels <= 200) {
      _loadNewer();
    }
  }

  // Scenario 1: Initial Load (Latest 30 items) -> _tailItems
  Future<void> _initLoad() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _service.fetchHighlights(limit: 30);
      if (mounted) {
        setState(() {
          // Response is Ascending [Old...New].
          // We reverse it for display since we use reverse: true on the list
          // This makes the newest item appear at the bottom (visual top when reversed)
          _tailItems.clear();
          _headItems.clear();
          // Store in descending order [New...Old] for reverse list display
          _tailItems.addAll(response.data.summaries.reversed);

          _isLoading = false;
        });
        // No need to scroll - reverse list starts at bottom automatically
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
    await _initLoad();
  }

  // Scenario 2: Load History (scroll to visual top = oldest items)
  Future<void> _loadHistory() async {
    if (_isFetchingMore || _isLoading || _tailItems.isEmpty) return;

    // Find oldest item currently known (last in _tailItems since it's descending)
    NewsSummary? oldestItem;
    if (_headItems.isNotEmpty) {
      // Head items contain older data
      final last =
          _headItems.lastWhere((e) => e is NewsSummary, orElse: () => null);
      if (last != null) oldestItem = last as NewsSummary;
    } else if (_tailItems.isNotEmpty) {
      // Tail items: [New...Old]. Last is oldest.
      final last =
          _tailItems.lastWhere((e) => e is NewsSummary, orElse: () => null);
      if (last != null) oldestItem = last as NewsSummary;
    }

    if (oldestItem == null) return;

    final oldestTime = int.parse(oldestItem.updateTime);

    _isFetchingMore = true;

    try {
      final response = await _service.fetchHighlights(
        endTime: oldestTime,
        limit: 30,
      );

      if (!mounted) return;

      final historyItems = response.data.summaries; // Ascending [Older...Old]
      final total = response.data.total;

      if (historyItems.isEmpty) {
        setState(() => _isFetchingMore = false);
        return;
      }

      setState(() {
        // historyItems: Ascending [Older...Old].
        // For _headItems in reverse list, we want descending.
        // Add to headItems for display above current content
        _headItems.addAll(historyItems.reversed.toList());

        if (total > historyItems.length) {
          final oldestFetchTime =
              int.parse(historyItems.first.updateTime); // Oldest fetched

          _headItems.add(GapToken(
            startTime: 0,
            endTime: oldestFetchTime,
            remainingCount: total - historyItems.length,
          ));
        }
        _isFetchingMore = false;
      });
    } catch (e) {
      setState(() => _isFetchingMore = false);
      _showSnack('加载历史失败: $e');
    }
  }

  // Scenario 3: Load Newer (scroll to visual bottom = newest items)
  Future<void> _loadNewer() async {
    if (_isFetchingMore || _isLoading || _tailItems.isEmpty) return;

    // Find newest item known (first in _tailItems since it's descending [New...Old])
    NewsSummary? newestItem;
    if (_tailItems.isNotEmpty) {
      // Tail: [New...Old]. First is newest.
      final first =
          _tailItems.firstWhere((e) => e is NewsSummary, orElse: () => null);
      if (first != null) newestItem = first as NewsSummary;
    }
    if (newestItem == null) return;

    final newestTime = int.parse(newestItem.updateTime);

    _isFetchingMore = true;

    try {
      final response = await _service.fetchHighlights(
        startTime: newestTime,
        limit: 30,
      );

      if (!mounted) return;

      final newItems = response.data.summaries; // Ascending [New...Newer]
      final total = response.data.total;

      if (newItems.isNotEmpty) {
        setState(() {
          // Insert at beginning since _tailItems is descending [New...Old]
          // newItems are Ascending [New...Newer], reverse to [Newer...New]
          // and insert at start
          _tailItems.insertAll(0, newItems.reversed);

          if (total > newItems.length) {
            // Gap for even newer content
            final newestFetchTime = int.parse(newItems.last.updateTime);
            _tailItems.insert(
                0,
                GapToken(
                  startTime: newestFetchTime,
                  endTime: 0,
                  remainingCount: total - newItems.length,
                ));
          }
        });
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) {
        setState(() => _isFetchingMore = false);
      }
    }
  }

  // Scenario 4: Gap Filling
  Future<void> _fillGap(GapToken gap, bool isHead) async {
    setState(() => _isFetchingMore = true);

    try {
      final response = await _service.fetchHighlights(
        startTime: gap.startTime == 0 ? null : gap.startTime,
        endTime: gap.endTime == 0 ? null : gap.endTime,
        limit: 30,
      );

      if (!mounted) return;

      final fetchedItems = response.data.summaries; // Ascending
      final total = response.data.total;

      setState(() {
        final list = isHead ? _headItems : _tailItems;
        final index = list.indexOf(gap);

        if (index != -1) {
          list.removeAt(index);
          // If Head (History): Fetched [Older...Old].
          // We want Descending for Head.
          if (isHead) {
            list.insertAll(index, fetchedItems.reversed.toList());
          } else {
            // Tail (Newer): Fetched [New...Newer].
            // We want Ascending.
            list.insertAll(index, fetchedItems);
          }

          if (total > fetchedItems.length) {
            // Re-add gap
            if (isHead) {
              // Gap is Older than fetched. (Top of Head)
              final oldestFetched = int.parse(fetchedItems.first.updateTime);
              list.insert(
                  index + fetchedItems.length,
                  GapToken(
                    startTime: 0,
                    endTime: oldestFetched,
                    remainingCount: total - fetchedItems.length,
                  ));
            } else {
              // Gap is Newer than fetched. (Bottom of Tail)
              final newestFetched = int.parse(fetchedItems.last.updateTime);
              list.insert(
                  index + fetchedItems.length,
                  GapToken(
                    startTime: newestFetched,
                    endTime: 0,
                    remainingCount: total - fetchedItems.length,
                  ));
            }
          }
        }
        _isFetchingMore = false;
      });
    } catch (e) {
      setState(() => _isFetchingMore = false);
      _showSnack('加载更多失败: $e');
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

    if (_tailItems.isEmpty && _headItems.isEmpty) {
      return const Center(
        child: Text('暂无数据', style: TextStyle(color: Colors.white54)),
      );
    }

    // Use reverse: true so the list naturally starts at the bottom
    // This avoids visible scroll animation on initial load
    return CustomScrollView(
      controller: _scrollController,
      reverse: true, // Start from bottom, newest items at visual bottom
      slivers: [
        // Main content (displayed in reverse order, so newest at bottom)
        SliverList(
          key: _centerKey,
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= _tailItems.length) {
                if (_isFetchingMore) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFFFF8C00)),
                      ),
                    ),
                  );
                }
                return null;
              }
              // With reverse: true, index 0 is at visual bottom
              // _tailItems[0] is newest, so it appears at bottom
              final item = _tailItems[index];
              return _buildItemWrapper(item, false);
            },
            childCount: _tailItems.length + (_isFetchingMore ? 1 : 0),
          ),
        ),

        // History Items (older, appear above when scrolling up)
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = _headItems[index];
              return _buildItemWrapper(item, true);
            },
            childCount: _headItems.length,
          ),
        ),
      ],
    );
  }

  Widget _buildItemWrapper(dynamic item, bool isHead) {
    if (item is GapToken) {
      return _buildGapItem(item, isHead);
    }
    if (item is NewsSummary) {
      return _buildTimelineSection(
          DslMarkdownSection(
            markdown: item.markDown,
            catalog: HighlightsCatalog.getCatalog(),
            onAction: _handleAction,
          ),
          1 // Show dot
          );
    }
    return const SizedBox.shrink();
  }

  Widget _buildGapItem(GapToken gap, bool isHead) {
    return _buildTimelineSection(
      InkWell(
        onTap: () => _fillGap(gap, isHead),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A35),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            children: [
              const Icon(Icons.history, color: Color(0xFF6B8EFF)),
              const SizedBox(height: 4),
              Text(
                '还有 ${gap.remainingCount} 条消息',
                style: const TextStyle(color: Color(0xFF6B8EFF), fontSize: 13),
              ),
              const Text(
                '点击加载',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
      -1,
    );
  }

  /// Builds a section with timeline decoration.
  Widget _buildTimelineSection(Widget content, int index) {
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
          child: _TimelineContentWrapper(
            showDot: index != -1,
            child: content,
          ),
        ),
      ],
    );
  }
}

/// Wraps content to add timeline dot indicator for targetHeader components.
class _TimelineContentWrapper extends StatelessWidget {
  const _TimelineContentWrapper({required this.child, this.showDot = true});

  final Widget child;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        // Blue dot indicator on the timeline (at the start of section)
        if (showDot)
          Positioned(
            left: -13, // 14 (line x) - 24 (padding left) - 3 (half dot width)
            top: 18, // Adjust to align with header
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
