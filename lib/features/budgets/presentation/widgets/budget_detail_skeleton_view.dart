import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'budget_skeleton_row.dart';

/// Loading placeholder of the budget detail (`NloPT`).
///
/// Pencil draws no loading frame for the detail, but the feature already
/// speaks in skeletons (`iVri4` on the list, `ktlIa` on the history), so a
/// bare spinner would break its own idiom. This mirrors the real geometry:
/// the hero card (icon-wrap + name/scope, big amount, progress track and its
/// two captions) and the first activity rows under the section header.
class BudgetDetailSkeletonView extends StatelessWidget {
  const BudgetDetailSkeletonView({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
        label: AppLocalizations.of(context).budgetDetailLoading,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 96),
          children: const [
            BudgetDetailHeroSkeleton(),
            SizedBox(height: 16),
            // A `ListView` stretches its children, so the section header's
            // bar has to be aligned or it would span the full width.
            Align(
              alignment: Alignment.centerLeft,
              child: BudgetSkeletonBox(width: 150, height: 13, radius: 4),
            ),
            SizedBox(height: 12),
            BudgetActivitySkeletonRow(),
            SizedBox(height: 14),
            BudgetActivitySkeletonRow(),
            SizedBox(height: 14),
            BudgetActivitySkeletonRow(),
            SizedBox(height: 14),
            BudgetActivitySkeletonRow(),
          ],
        ),
      );
}

/// The hero card's placeholder (`NloPT/gPZ6b`).
class BudgetDetailHeroSkeleton extends StatelessWidget {
  const BudgetDetailHeroSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BudgetSkeletonBox(width: 44, height: 44, radius: 14),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BudgetSkeletonBox(width: 140, height: 14, radius: 4),
                  SizedBox(height: 6),
                  BudgetSkeletonBox(width: 96, height: 10, radius: 4),
                ],
              ),
            ],
          ),
          SizedBox(height: 18),
          BudgetSkeletonBox(width: 90, height: 10, radius: 4),
          SizedBox(height: 8),
          BudgetSkeletonBox(width: 190, height: 28),
          SizedBox(height: 16),
          BudgetSkeletonBox(width: double.infinity, height: 8, radius: 4),
          SizedBox(height: 10),
          Row(
            children: [
              BudgetSkeletonBox(width: 150, height: 10, radius: 4),
              Spacer(),
              SizedBox(width: 12),
              BudgetSkeletonBox(width: 80, height: 10, radius: 4),
            ],
          ),
        ],
      ),
    );
  }
}

/// One placeholder of the period activity (`Budget Activity Row`).
class BudgetActivitySkeletonRow extends StatelessWidget {
  const BudgetActivitySkeletonRow({super.key});

  @override
  Widget build(BuildContext context) => const Row(
        children: [
          BudgetSkeletonBox(width: 44, height: 44, radius: 14),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BudgetSkeletonBox(width: 130, height: 13, radius: 4),
              SizedBox(height: 6),
              BudgetSkeletonBox(width: 88, height: 10, radius: 4),
            ],
          ),
          Spacer(),
          SizedBox(width: 12),
          BudgetSkeletonBox(width: 72, height: 13, radius: 4),
        ],
      );
}
