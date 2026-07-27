import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/debts_summary.dart';
import '../utils/debt_format.dart';
import 'debt_summary_column.dart';

/// The list's summary card (`u2Xje`): "Yo debo" (neutral) vs "Me deben"
/// (`$income-text` green), segmented by a single currency (the `COP` chip).
///
/// Fase 0 never normalizes across currencies, so the list renders one of these
/// per currency present in the totals (see `12-multi-moneda.md`).
class DebtSummaryCard extends StatelessWidget {
  const DebtSummaryCard({required this.total, super.key});

  final DebtCurrencyTotal total;

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
                  label: l10n.debtDirectionIOwe,
                  amount: DebtFormat.amount(
                    total.iOweOutstandingMinor,
                    total.currency,
                  ),
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
                  label: l10n.debtDirectionOwedToMe,
                  amount: DebtFormat.amount(
                    total.owedToMeOutstandingMinor,
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
