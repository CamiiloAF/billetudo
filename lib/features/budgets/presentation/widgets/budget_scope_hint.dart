import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// The informative strip shown when the scope is "Todo" (`yfy35/dd4X6`).
///
/// With the toggle on "Todo" the Cuentas/Categorías rows are hidden because
/// they are redundant; this strip is what tells the user what "Todo" actually
/// covers, so hiding the rows does not read as a missing control.
class BudgetScopeHint extends StatelessWidget {
  const BudgetScopeHint({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusField),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.globe, size: 18, color: colors.primaryOnSoft),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context).budgetFormScopeAllHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.primaryOnSoftStrong,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
