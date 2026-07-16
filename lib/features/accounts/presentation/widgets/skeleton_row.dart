import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// The `Skeleton Row` component: the loading placeholder of an account row.
///
/// It copies `AccountCard`'s geometry on purpose, so the list does not jump
/// when the real data lands.
class SkeletonRow extends StatelessWidget {
  const SkeletonRow({this.nameWidth = 120, this.typeWidth = 70, super.key});

  /// Varying the widths between rows keeps the loading list from looking like
  /// a stamped pattern.
  final double nameWidth;
  final double typeWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(width: nameWidth, height: 14),
                const SizedBox(height: 8),
                SkeletonBlock(width: typeWidth, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const SkeletonBlock(width: 76, height: 16),
        ],
      ),
    );
  }
}

/// A single solid `$border` block standing in for text while it loads.
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
        color: context.colors.border,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
