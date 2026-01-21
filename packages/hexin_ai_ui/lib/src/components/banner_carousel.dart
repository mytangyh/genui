// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Schema for banner carousel component.
///
/// DSL Example:
/// ```json
/// {
///   "type": "banner_carousel",
///   "props": {
///     "items": [
///       {"route": "client://ai.route/1", "image_url": "https://example.com/1.png"},
///       {"route": "client://ai.route/2", "image_url": "https://example.com/2.png"}
///     ],
///     "autoPlay": true,
///     "duration": 3000
///   }
/// }
/// ```
final _bannerCarouselSchema = S.object(
  description: 'Banner 轮播图组件',
  properties: {
    'items': ListSchema(
      description: 'Banner 列表',
      items: S.object(
        properties: {
          'image_url': S.string(description: '图片 URL'),
          'route': S.string(description: '点击跳转路由'),
          'title': S.string(description: '标题（可选）'),
        },
        required: ['image_url'],
      ),
    ),
    'height': S.number(description: '轮播图高度（可选，默认160）'),
    'autoPlay': S.boolean(description: '是否自动播放（默认true）'),
    'duration': S.integer(description: '自动播放间隔毫秒（默认3000）'),
  },
  required: ['items'],
);

/// Banner carousel component.
final bannerCarousel = CatalogItem(
  name: 'banner_carousel',
  dataSchema: _bannerCarouselSchema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "banner_carousel": {
              "items": [
                {"route": "client://ai.route/1", "image_url": "https://via.placeholder.com/400x160/FF8C00/FFFFFF?text=Banner+1"},
                {"route": "client://ai.route/2", "image_url": "https://via.placeholder.com/400x160/6B8EFF/FFFFFF?text=Banner+2"},
                {"route": "client://ai.route/3", "image_url": "https://via.placeholder.com/400x160/B06BFF/FFFFFF?text=Banner+3"}
              ],
              "autoPlay": true,
              "duration": 3000
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final List<dynamic> items = data['items'] as List<dynamic>? ?? [];
    final num height = data['height'] as num? ?? 160;
    final bool autoPlay = data['autoPlay'] as bool? ?? true;
    final num duration = data['duration'] as num? ?? 3000;

    return _BannerCarousel(
      items: items.map((item) {
        final Map<String, Object?> itemData = item as Map<String, Object?>;
        return _BannerItem(
          imageUrl: itemData['image_url'] as String? ?? '',
          route: itemData['route'] as String?,
          title: itemData['title'] as String?,
        );
      }).toList(),
      height: height.toDouble(),
      autoPlay: autoPlay,
      duration: Duration(milliseconds: duration.toInt()),
      onItemTap: (route) {
        if (route != null) {
          context.dispatchEvent(
            UserActionEvent(
              name: 'navigate',
              sourceComponentId: context.id,
              context: {'route': route},
            ),
          );
        }
      },
    );
  },
);

class _BannerItem {
  const _BannerItem({required this.imageUrl, this.route, this.title});

  final String imageUrl;
  final String? route;
  final String? title;
}

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel({
    required this.items,
    this.height = 160,
    this.autoPlay = true,
    this.duration = const Duration(milliseconds: 3000),
    this.onItemTap,
  });

  final List<_BannerItem> items;
  final double height;
  final bool autoPlay;
  final Duration duration;
  final void Function(String? route)? onItemTap;

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    if (widget.autoPlay && widget.items.length > 1) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(widget.duration, (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % widget.items.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: widget.height,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                return _buildBannerItem(widget.items[index]);
              },
            ),
          ),
          if (widget.items.length > 1) ...[
            const SizedBox(height: 8),
            _buildIndicators(),
          ],
        ],
      ),
    );
  }

  Widget _buildBannerItem(_BannerItem item) {
    return GestureDetector(
      onTap: () => widget.onItemTap?.call(item.route),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image or placeholder
            _buildImage(item.imageUrl),
            // Gradient overlay for title
            if (item.title != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Text(
                    item.title!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String url) {
    if (url.isEmpty) {
      return _buildPlaceholder();
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildPlaceholder(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
            strokeWidth: 2,
            color: Colors.white.withOpacity(0.5),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholder(
          child: const Icon(
            Icons.image_not_supported,
            color: Colors.white54,
            size: 32,
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder({Widget? child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF2D3A4D), const Color(0xFF1A2332)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: child),
    );
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.items.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: isActive
                ? const Color(0xFF6B8EFF)
                : Colors.white.withOpacity(0.3),
          ),
        );
      }),
    );
  }
}
