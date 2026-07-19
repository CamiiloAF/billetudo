import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// `Scheduled Skeleton Card` (`asOGI`): the loading placeholder of a
/// `ScheduledCard`, with the same geometry (44px icon tile, two text lines,
/// a chip row and an amount block) so the list does not jump when the real
/// data lands.
class ScheduledSkeletonCard extends StatelessWidget {
  const ScheduledSkeletonCard({
    this.titleWidth = 120,
    this.subtitleWidth = 150,
    super.key,
  });

  final double titleWidth;
  final double subtitleWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Square with the icon tile's own radius, not a circle: the
          // skeleton has to promise the shape that is about to land.
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.skeleton,
              borderRadius: BorderRadius.circular(AppTheme.radiusField),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScheduledSkeletonBlock(width: titleWidth, height: 14),
                const SizedBox(height: 6),
                ScheduledSkeletonBlock(width: subtitleWidth, height: 12),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    ScheduledSkeletonBlock(width: 72, height: 18, radius: 10),
                    SizedBox(width: 6),
                    ScheduledSkeletonBlock(width: 88, height: 18, radius: 10),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const ScheduledSkeletonBlock(width: 76, height: 16),
        ],
      ),
    );
  }
}

/// A single rounded `skeleton`-filled placeholder block.
class ScheduledSkeletonBlock extends StatelessWidget {
  const ScheduledSkeletonBlock({
    required this.width,
    required this.height,
    this.radius = 6,
    super.key,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.skeleton,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
