// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../catalog/catalog.dart';
import '../dsl/dsl.dart';
import '../models/highlights_response.dart';
import '../services/highlights_service.dart';

/// Page displaying real-time financial highlights and news.
///
/// Fetches data from the news aggregations API and renders it using
/// DSL-based components from the catalog.
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF8C00)),
              )
            : _errorMessage != null
            ? Center(
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
              )
            : _summaries.isEmpty
            ? Center(
                child: Text(
                  '暂无数据',
                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _summaries.length,
                itemBuilder: (context, index) {
                  final summary = _summaries[index];

                  // Parse DSL blocks from the markdown
                  final rawBlocks = DslParser.extractBlocks(summary.markDown);

                  // Unwrap simplyDSL format: extract children from the wrapper
                  final dslBlocks = <Map<String, dynamic>>[];
                  for (final block in rawBlocks) {
                    if (block.containsKey('simplyDSL') &&
                        block.containsKey('children')) {
                      // Extract children from simplyDSL wrapper
                      final children = block['children'] as List<dynamic>;
                      for (final child in children) {
                        if (child is Map<String, dynamic>) {
                          dslBlocks.add(child);
                        }
                      }
                    } else {
                      // Regular DSL block without wrapper
                      dslBlocks.add(block);
                    }
                  }

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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Render DSL blocks directly without nested ListView
                            ...dslBlocks.map((block) {
                              return DslSurface(
                                dsl: block,
                                catalog: FinancialCatalog.getDslCatalog(),
                                onAction: _handleAction,
                              );
                            }),


                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

/// Custom painter for dashed vertical line
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
