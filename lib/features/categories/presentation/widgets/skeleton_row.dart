import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// The categories list's `Skeleton Row` (`QZAKU`): the same geometry as
/// `CategoryAccordionRow`, so nothing jumps when the data lands.
class CategorySkeletonRow extends StatelessWidget {
  const CategorySkeletonRow({this.nameWidth = 120, super.key});

  /// Varying the width between rows keeps the loading list from looking like
  /// a stamped pattern.
  final double nameWidth;

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
            child: Container(
              width: nameWidth,
              height: 14,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.chevron_right, color: colors.border),
        ],
      ),
    );
  }
}
