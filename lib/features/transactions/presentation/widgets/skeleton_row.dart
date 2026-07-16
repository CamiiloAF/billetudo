import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// The loading placeholder of a transaction row, same geometry as
/// `TransactionRow` so the list does not jump when the real data lands.
class SkeletonRow extends StatelessWidget {
  const SkeletonRow(
      {this.titleWidth = 120, this.subtitleWidth = 90, super.key});

  final double titleWidth;
  final double subtitleWidth;

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
          const SkeletonBlock(width: 70, height: 16),
        ],
      ),
    );
  }
}

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
