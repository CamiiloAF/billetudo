import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/money_formatter.dart';
import '../balance_mini_card.dart';
import 'currency_group.dart';

/// One currency group's header ("TU DINERO" total block + currency/count
/// chip) plus its account rows, in `BalancesSheet`.
class CurrencyGroupSection extends StatelessWidget {
  const CurrencyGroupSection({
    required this.group,
    required this.onOpenAccountMovements,
    super.key,
  });

  final CurrencyGroup group;
  final ValueChanged<String>? onOpenAccountMovements;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    const money = MoneyFormatter();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.homeBalancesSheetTotalLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                  Text(
                    money.formatSymbol(
                      group.totalMinor,
                      currencyCode: group.currency,
                    ),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (group.excludesSomething)
                    Text(
                      l10n.homeBalancesSheetExcludesNote,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors.muted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.homeBalancesSheetCurrencyCount(
                  group.currency,
                  group.entries.length,
                ),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final entry in group.entries)
          BalanceMiniCard(
            key: ValueKey(entry.account.id),
            entry: entry,
            onTap: onOpenAccountMovements == null
                ? null
                : () {
                    Navigator.of(context).pop();
                    onOpenAccountMovements!(entry.account.id);
                  },
          ),
      ],
    );
  }
}
