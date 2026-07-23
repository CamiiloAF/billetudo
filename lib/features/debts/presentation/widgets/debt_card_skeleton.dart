import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'debt_skeleton_box.dart';

/// Loading placeholder for `DebtCard` (`J2icQQ`): the same geometry in
/// `$skeleton`, so nothing jumps when the real card lands.
class DebtCardSkeleton extends StatelessWidget {
  const DebtCardSkeleton({
    this.nameWidth = 130,
    this.counterpartyWidth = 90,
    super.key,
  });

  final double nameWidth;
  final double counterpartyWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const DebtSkeletonBox(width: 44, height: 44, radius: 14),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DebtSkeletonBox(width: nameWidth, height: 14),
                  const SizedBox(height: 8),
                  DebtSkeletonBox(width: counterpartyWidth, height: 10),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DebtSkeletonBox(width: 120, height: 18),
              DebtSkeletonBox(width: 76, height: 11),
            ],
          ),
          const SizedBox(height: 12),
          const DebtSkeletonBox(height: 8),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DebtSkeletonBox(width: 92, height: 16, radius: 8),
              DebtSkeletonBox(width: 60, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}
