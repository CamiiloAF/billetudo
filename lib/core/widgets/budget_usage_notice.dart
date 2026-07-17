import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme/app_colors.dart';

/// A neutral, non-punitive line telling the user how many budgets reference the
/// account/category they are about to delete (Presupuestos HU-06). The budget
/// is never cascaded — this is information, not a warning.
///
/// Renders nothing when [count] is zero, so callers can drop it in
/// unconditionally.
class BudgetUsageNotice extends StatelessWidget {
  const BudgetUsageNotice({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        l10n.deleteImpactBudgets(count),
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}
