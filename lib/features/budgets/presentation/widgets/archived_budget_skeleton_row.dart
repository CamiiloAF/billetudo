import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'budget_skeleton_row.dart';

/// Loading placeholder of the history's `Archived Budget Row` (`Ote7d`).
///
/// Pencil has no skeleton component for the history (only `iVri4`, which is
/// the *list* row's placeholder and has a different geometry), so this mirrors
/// `Ote7d` bar for bar instead: a body zone (icon-wrap + name/scope stack +
/// the closed-on date) and the footer zone with its `$border` top rule.
class ArchivedBudgetSkeletonRow extends StatelessWidget {
  const ArchivedBudgetSkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BudgetSkeletonBox(width: 40, height: 40, radius: 12),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BudgetSkeletonBox(width: 120, height: 14, radius: 4),
                        SizedBox(height: 6),
                        BudgetSkeletonBox(width: 88, height: 10, radius: 4),
                      ],
                    ),
                    Spacer(),
                    SizedBox(width: 12),
                    BudgetSkeletonBox(width: 76, height: 10, radius: 4),
                  ],
                ),
                SizedBox(height: 14),
                BudgetSkeletonBox(width: 180, height: 11, radius: 4),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                BudgetSkeletonBox(width: 92, height: 14, radius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
