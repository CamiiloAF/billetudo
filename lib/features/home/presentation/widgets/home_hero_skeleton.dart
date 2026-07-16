import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'recent_activity_skeleton_row.dart';

/// The hero's loading placeholder (HU-09): same height and radius as
/// `HomeHeroCard`, filled with `skeleton` blocks over a `muted` surface so it
/// does not flash the brand gradient before data lands.
class HomeHeroSkeleton extends StatelessWidget {
  const HomeHeroSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(AppTheme.sheetRadius),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBlock(width: 120, height: 14),
              Spacer(),
              SkeletonBlock(width: 92, height: 36),
            ],
          ),
          SizedBox(height: 16),
          SkeletonBlock(width: 180, height: 40),
          SizedBox(height: 16),
          SkeletonBlock(width: 220, height: 14),
        ],
      ),
    );
  }
}
