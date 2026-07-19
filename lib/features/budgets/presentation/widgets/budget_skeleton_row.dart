import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// The `Budget Skeleton Row` component (`iVri4`): the loading placeholder of a
/// budget line. Uses the `$skeleton` token (NOT `$border`, which is nearly
/// invisible over `$surface` in dark).
class BudgetSkeletonRow extends StatelessWidget {
  const BudgetSkeletonRow({super.key});

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
      // Mirrors `iVri4` bar for bar, so the placeholder announces the very
      // row that arrives: one name line on the left, the label+amount stack
      // on the right, then the loose meta line and the track.
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BudgetSkeletonBox(width: 44, height: 44, radius: 14),
              SizedBox(width: 12),
              BudgetSkeletonBox(width: 120, height: 14, radius: 4),
              Spacer(),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  BudgetSkeletonBox(width: 54, height: 9, radius: 4),
                  SizedBox(height: 6),
                  BudgetSkeletonBox(width: 84, height: 16, radius: 4),
                ],
              ),
            ],
          ),
          SizedBox(height: 14),
          BudgetSkeletonBox(width: 170, height: 10, radius: 4),
          SizedBox(height: 14),
          BudgetSkeletonBox(width: double.infinity, height: 8, radius: 4),
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
