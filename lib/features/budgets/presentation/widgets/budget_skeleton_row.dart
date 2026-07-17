import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// The `Budget Skeleton Row` component (`iVri4`): the loading placeholder of a
/// budget line. Uses the `$skeleton` token (NOT `$border`, which is nearly
/// invisible over `$surface` in dark).
class BudgetSkeletonRow extends StatelessWidget {
  const BudgetSkeletonRow({this.nameWidth = 140, super.key});

  final double nameWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BudgetSkeletonBox(width: 44, height: 44, radius: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BudgetSkeletonBox(width: nameWidth, height: 14),
                    const SizedBox(height: 8),
                    const BudgetSkeletonBox(width: 100, height: 12),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const BudgetSkeletonBox(width: 70, height: 16),
            ],
          ),
          const SizedBox(height: 16),
          const BudgetSkeletonBox(width: double.infinity, height: 8, radius: 8),
        ],
      ),
    );
  }
}

class BudgetSkeletonBox extends StatelessWidget {
  const BudgetSkeletonBox({
    required this.width,
    required this.height,
    this.radius = 6,
    super.key,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.colors.skeleton,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}
