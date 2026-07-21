import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'skeleton_row.dart';

/// The Total Card's own placeholder, shown before the 4 `Skeleton Row`s
/// (`Jyvry` in `sh7r2`) — the loading state should not jump from the header
/// straight to the list, skipping the card's shape.
class AccountsTotalCardSkeleton extends StatelessWidget {
  const AccountsTotalCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.colors.muted,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBlock(width: 120, height: 14, borderRadius: 4),
          SizedBox(height: 6),
          SkeletonBlock(width: 180, height: 36),
          SizedBox(height: 6),
          SkeletonBlock(width: 140, height: 14, borderRadius: 4),
        ],
      ),
    );
  }
}
