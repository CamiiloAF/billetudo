import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import 'chart_skeleton_block.dart';
import 'chart_skeleton_view.dart' show ChartSkeletonView;

/// The hero block of [ChartSkeletonView]: title/value/stats placeholders.
class ChartSkeletonHero extends StatelessWidget {
  const ChartSkeletonHero({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChartSkeletonBlock(width: 180, height: 14),
          SizedBox(height: 6),
          ChartSkeletonBlock(width: 210, height: 32),
          SizedBox(height: 6),
          Row(
            children: [
              ChartSkeletonBlock(width: 92, height: 28),
              SizedBox(width: 20),
              ChartSkeletonBlock(width: 86, height: 28),
            ],
          ),
        ],
      ),
    );
  }
}
