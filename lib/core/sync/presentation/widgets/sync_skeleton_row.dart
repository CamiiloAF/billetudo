import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

/// `Sync Skeleton Row` (`UtO4B`): mirrors the real geometry of
/// `SyncPendingRow` so the jump from skeleton to content moves nothing.
///
/// Fills are always `$skeleton`, never `$border` — that token is for real
/// dividers and is nearly invisible in dark mode.
class SyncSkeletonRow extends StatelessWidget {
  const SyncSkeletonRow({
    this.firstLineWidth = 170,
    this.secondLineWidth = 110,
    super.key,
  });

  /// Varied between rows so the list does not read as a repeating pattern.
  final double firstLineWidth;
  final double secondLineWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.skeleton,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SyncSkeletonBlock(width: firstLineWidth, height: 13),
                const SizedBox(height: 8),
                SyncSkeletonBlock(width: secondLineWidth, height: 10),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const SyncSkeletonBlock(width: 8, height: 14),
        ],
      ),
    );
  }
}

/// One `$skeleton` placeholder block, radius 4.
class SyncSkeletonBlock extends StatelessWidget {
  const SyncSkeletonBlock({
    required this.height,
    this.width,
    super.key,
  });

  /// `null` fills the available width.
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.skeleton,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
