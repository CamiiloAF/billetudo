import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The Home's `Transaction Skeleton Row` (HU-09): a flat loading placeholder
/// that mirrors `RecentActivityRow`'s geometry — a 44x44 icon circle, two text
/// lines and an amount block — all filled with the `skeleton` token.
///
/// Flat on purpose (no card): the real row it stands in for is flat too.
class RecentActivitySkeletonRow extends StatelessWidget {
  const RecentActivitySkeletonRow({
    this.titleWidth = 140,
    this.subtitleWidth = 90,
    super.key,
  });

  final double titleWidth;
  final double subtitleWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(color: colors.skeleton, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(width: titleWidth, height: 14),
                const SizedBox(height: 8),
                SkeletonBlock(width: subtitleWidth, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const SkeletonBlock(width: 68, height: 16),
        ],
      ),
    );
  }
}

/// A single rounded `skeleton`-filled placeholder block.
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({required this.width, required this.height, super.key});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.skeleton,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
