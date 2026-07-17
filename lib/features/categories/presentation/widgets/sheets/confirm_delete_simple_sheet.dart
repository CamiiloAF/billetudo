import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/budget_usage_notice.dart';

/// HU-04 case 1: no dependents (`jngMo`).
///
/// The `trash-2` icon is `$primary`/`$primary-soft`, never red: the delete is
/// reversible via the trash, so nothing here is alarming.
class ConfirmDeleteSimpleSheet extends StatelessWidget {
  const ConfirmDeleteSimpleSheet({this.budgetCount = 0, super.key});

  /// Budgets whose scope references this category (Presupuestos HU-06).
  final int budgetCount;

  /// Resolves to `true` when the user confirms.
  static Future<bool?> show(BuildContext context, {int budgetCount = 0}) =>
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (context) =>
            ConfirmDeleteSimpleSheet(budgetCount: budgetCount),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.primarySoft,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(LucideIcons.trash,
                  color: colors.primaryOnSoft, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.categoryDeleteSimpleTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.categoryDeleteSimpleMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colors.textSecondary),
            ),
            BudgetUsageNotice(count: budgetCount),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.commonCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(LucideIcons.trash),
                    label: Text(l10n.commonDelete),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
