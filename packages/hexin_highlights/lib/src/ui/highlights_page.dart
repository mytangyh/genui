// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:hexin_dsl/hexin_dsl.dart';

import '../catalog/highlights_catalog.dart';
import '../models/highlights_response.dart';
import '../services/highlights_service.dart';

/// Page displaying real-time financial highlights and news.
///
/// Uses DslMarkdownPage for flexible markdown rendering with embedded DSL.
/// Each summary is rendered as a markdown section with timeline decoration.
class HighlightsPage extends StatefulWidget {
  const HighlightsPage({super.key});

  @override
  State<HighlightsPage> createState() => _HighlightsPageState();
}

class _HighlightsPageState extends State<HighlightsPage>
    with AutomaticKeepAliveClientMixin {
  final HighlightsService _service = HighlightsService();

  bool _isLoading = true;
  String? _errorMessage;
  List<NewsSummary> _summaries = [];

  @override
  void initState() {
    super.initState();
    _loadHighlights();
  }

  Future<void> _loadHighlights() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _service.fetchHighlights(limit: 30);
      if (mounted) {
        setState(() {
          _summaries = response.data.summaries;
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

  void _handleAction(String actionName, Map<String, dynamic> actionContext) {
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
        onRefresh: _loadHighlights,
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
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadHighlights,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C00),
              ),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_summaries.isEmpty) {
      return Center(
        child: Text(
          '暂无数据',
          style: TextStyle(color: Colors.white.withOpacity(0.5)),
        ),
      );
    }

    // Use DslMarkdownPage for flexible rendering
    return DslMarkdownPage(
      markdownSections: _summaries.map((s) => s.markDown).toList(),
      catalog: HighlightsCatalog.getCatalog(),
      onAction: _handleAction,
      sectionBuilder: (content, index) => _buildTimelineSection(content, index),
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
            child: content,
          ),
        ),
      ],
    );
  }
}

/// Wraps content to add timeline dot indicator for targetHeader components.
class _TimelineContentWrapper extends StatelessWidget {
  const _TimelineContentWrapper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The blue dot is now added in DslMarkdownSection for targetHeader
    // components. This wrapper provides consistent padding.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        // Blue dot indicator on the timeline (at the start of section)
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
