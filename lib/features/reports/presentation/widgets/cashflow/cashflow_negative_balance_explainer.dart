import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';

/// The negative-balance explainer + "Ver en qué se fue" link
/// (`hLmoN/pZbct`+`hLmoN/r656T`): the two-frase treatment that keeps a red
/// month from reading as a judgement (`design-system/billetudo/pages/
/// graficas.md`, "Balance negativo"). The amount itself stays
/// `$text-primary`, never `$expense` — that decision lives in
/// `CashflowNetHero`, this widget only carries the second sentence and the
/// outward link.
class CashflowNegativeBalanceExplainer extends StatelessWidget {
  const CashflowNegativeBalanceExplainer({
    required this.explanation,
    required this.onViewCategories,
    super.key,
  });

  final String explanation;
  final VoidCallback onViewCategories;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          explanation,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: colors.textSecondary,
          ),
        ),
        InkWell(
          onTap: onViewCategories,
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.reportsCashflowViewCategoriesLink,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.primaryOnSoft,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  LucideIcons.chevronRight,
                  size: 15,
                  color: colors.primaryOnSoft,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
