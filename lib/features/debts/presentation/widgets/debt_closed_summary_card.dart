import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/debts_summary.dart';
import '../utils/debt_format.dart';
import 'debt_summary_column.dart';

/// The "Cerradas" tab's summary card (extension, HU-07, `vaNHd`): same
/// `DebtSummaryCard` chrome, but with past-tense labels — "Pagué" / "Me
/// pagaron" — and values recalculated over the closed debts, never the open
/// list's outstanding totals. Same color treatment as the open card: "Pagué"
/// keeps the label+icon neutral (`$text-secondary`) with the amount in
/// `$text-primary`; "Me pagaron" stays fully `$income-text` green.
class DebtClosedSummaryCard extends StatelessWidget {
  const DebtClosedSummaryCard({required this.total, super.key});

  final DebtClosedCurrencyTotal total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.debtsSummaryTitle,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.muted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  total.currency,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DebtSummaryColumn(
                  icon: LucideIcons.arrowUpRight,
                  label: l10n.debtsClosedPaidLabel,
                  amount:
                      DebtFormat.amount(total.iOwePaidMinor, total.currency),
                  labelColor: colors.textSecondary,
                  amountColor: colors.textPrimary,
                ),
              ),
              const SizedBox(width: 14),
              Container(width: 1, height: 42, color: colors.border),
              const SizedBox(width: 14),
              Expanded(
                child: DebtSummaryColumn(
                  icon: LucideIcons.arrowDownLeft,
                  label: l10n.debtsClosedCollectedLabel,
                  amount: DebtFormat.amount(
                    total.owedToMeCollectedMinor,
                    total.currency,
                  ),
                  labelColor: colors.incomeText,
                  amountColor: colors.incomeText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
