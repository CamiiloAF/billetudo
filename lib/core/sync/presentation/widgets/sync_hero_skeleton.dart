import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import 'sync_skeleton_row.dart';

/// The loading twin of `SyncHero` (`ZPmWi`): same head, body, time row and
/// CTA geometry, drawn with `$skeleton` blocks.
///
/// It exists for SQLite latency, not for the network: HU-08 rules out a
/// loading state that depends on the cloud. If the local read is immediate,
/// this is never seen.
class SyncHeroSkeleton extends StatelessWidget {
  const SyncHeroSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.skeleton,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SyncSkeletonBlock(width: 200, height: 18),
                  SizedBox(height: 8),
                  SyncSkeletonBlock(width: 140, height: 12),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SyncSkeletonBlock(height: 11),
          const SizedBox(height: 8),
          const SyncSkeletonBlock(height: 11),
          const SizedBox(height: 8),
          const SyncSkeletonBlock(width: 190, height: 11),
          const SizedBox(height: 12),
          const Row(
            children: [
              SyncSkeletonBlock(width: 15, height: 15),
              SizedBox(width: 7),
              SyncSkeletonBlock(width: 180, height: 12),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: colors.skeleton,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        ],
      ),
    );
  }
}
