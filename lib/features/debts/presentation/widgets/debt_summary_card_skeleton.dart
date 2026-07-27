import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'debt_skeleton_box.dart';

/// Loading placeholder for `DebtSummaryCard` (`JnH8U`): head chip + two
/// columns, in `$skeleton`.
class DebtSummaryCardSkeleton extends StatelessWidget {
  const DebtSummaryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DebtSkeletonBox(width: 80, height: 13),
              DebtSkeletonBox(width: 40, height: 18, radius: 8),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DebtSkeletonBox(width: 70, height: 11),
                    SizedBox(height: 8),
                    DebtSkeletonBox(width: 120, height: 22),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Container(width: 1, height: 42, color: colors.border),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DebtSkeletonBox(width: 70, height: 11),
                    SizedBox(height: 8),
                    DebtSkeletonBox(width: 110, height: 22),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
