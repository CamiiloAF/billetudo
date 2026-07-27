import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// The history's subheader (`KfPyk/IMgeg`): "Presupuestos cerrados" plus the
/// reassuring hint that closing is not deleting.
class ArchivedBudgetsSubheader extends StatelessWidget {
  const ArchivedBudgetsSubheader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.budgetsHistorySubtitle,
            style: theme.textTheme.titleSmall?.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.budgetsHistoryHint,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
