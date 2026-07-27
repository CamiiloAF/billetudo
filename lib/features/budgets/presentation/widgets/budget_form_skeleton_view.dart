import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'budget_skeleton_row.dart';

/// Loading placeholder of the budget form while an existing budget is read
/// (`a3gGPM`, edit mode).
///
/// Same reason as the detail's: the feature already announces its content
/// with skeletons, so a bare spinner would break the idiom. The shapes follow
/// `a3gGPM/lBpTl` section by section — icon + name, amount, scope, repeat,
/// period and the navigation rows — so the fields do not jump when they
/// arrive.
class BudgetFormSkeletonView extends StatelessWidget {
  const BudgetFormSkeletonView({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
        label: AppLocalizations.of(context).budgetFormLoading,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
          children: const [
            Align(
              alignment: Alignment.centerLeft,
              child: BudgetSkeletonBox(width: 110, height: 11, radius: 4),
            ),
            SizedBox(height: 6),
            Row(
              children: [
                BudgetSkeletonBox(width: 52, height: 52, radius: 14),
                SizedBox(width: 10),
                Expanded(child: BudgetFormFieldSkeleton()),
              ],
            ),
            SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: BudgetSkeletonBox(width: 60, height: 11, radius: 4),
            ),
            SizedBox(height: 6),
            BudgetFormFieldSkeleton(height: 74),
            SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: BudgetSkeletonBox(width: 72, height: 11, radius: 4),
            ),
            SizedBox(height: 6),
            BudgetFormFieldSkeleton(height: 44),
            SizedBox(height: 10),
            BudgetFormFieldSkeleton(),
            SizedBox(height: 10),
            BudgetFormFieldSkeleton(),
            SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: BudgetSkeletonBox(width: 66, height: 11, radius: 4),
            ),
            SizedBox(height: 6),
            BudgetFormFieldSkeleton(height: 44),
            SizedBox(height: 18),
            BudgetFormFieldSkeleton(),
            SizedBox(height: 10),
            BudgetFormFieldSkeleton(),
            SizedBox(height: 10),
            BudgetFormFieldSkeleton(),
          ],
        ),
      );
}

/// The outline of one form field: the real row's border and radius with an
/// empty `$surface` inside, so the placeholder reads as a field and not as a
/// solid bar.
class BudgetFormFieldSkeleton extends StatelessWidget {
  const BudgetFormFieldSkeleton({this.height = 50, super.key});

  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusField),
        border: Border.all(color: colors.border),
      ),
      child: const BudgetSkeletonBox(width: 140, height: 12, radius: 4),
    );
  }
}
