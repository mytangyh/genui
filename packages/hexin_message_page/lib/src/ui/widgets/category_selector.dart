// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../models/message_models.dart';

/// A horizontal scrollable category selector for message forums.
class CategorySelector extends StatelessWidget {
  final List<MessageForum> categories;
  final String selectedId;
  final ValueChanged<String> onSelect;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A24),
        border: Border(
          top: BorderSide(color: Color(0xFF2A2A35), width: 0.5),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: categories.map((category) {
            final isSelected = category.fid == selectedId;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _CategoryChip(
                label: category.fname,
                count: category.number,
                isSelected: isSelected,
                onTap: () => onSelect(category.fid),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2B7EFF) : const Color(0xFF232232),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(height: 2),
              Text(
                '未读$count',
                style: TextStyle(
                  color: isSelected ? Colors.white70 : Colors.white38,
                  fontSize: 11,
                ),
              ),
            ] else ...[
              const SizedBox(height: 2),
              Text(
                '未读',
                style: TextStyle(
                  color: isSelected ? Colors.white70 : Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
