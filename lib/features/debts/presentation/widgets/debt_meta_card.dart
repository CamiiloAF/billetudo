import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/debt.dart';
import '../utils/debt_format.dart';
import 'debt_meta_row.dart';

/// The detail meta card (`xKwGM`): counterparty, due date, estimated daily
/// growth, and the "Actualizar saldo" action (`sliders-horizontal`, never
/// `refresh-cw` — it is not a sync).
class DebtMetaCard extends StatelessWidget {
  const DebtMetaCard({
    required this.debt,
    required this.dailyGrowthMinor,
    required this.onUpdateBalance,
    super.key,
  });

  final Debt debt;

  /// Estimated interest per day, or `null` when the debt does not accrue
  /// automatically — the growth line is then omitted.
  final int? dailyGrowthMinor;

  final VoidCallback onUpdateBalance;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final dueDate = debt.dueDate;
    final growth = dailyGrowthMinor;

    final metaRows = <Widget>[
      if (debt.counterparty != null)
        DebtMetaRow(icon: LucideIcons.landmark, text: debt.counterparty!),
      if (dueDate != null)
        DebtMetaRow(
          icon: LucideIcons.calendar,
          text: l10n.debtDueOn(DebtFormat.dateLong(context, dueDate)),
        ),
      if (growth != null)
        DebtMetaRow(
          icon: LucideIcons.trendingUp,
          text: l10n.debtDetailGrowth(
            DebtFormat.amount(growth, debt.currency),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: colors.muted,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              l10n.debtDetailEstimated,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final row in metaRows) ...[
            row,
            const SizedBox(height: 10),
          ],
          if (metaRows.isNotEmpty) ...[
            Container(height: 1, color: colors.border),
            const SizedBox(height: 10),
          ],
          InkWell(
            onTap: onUpdateBalance,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Icon(
                  LucideIcons.slidersHorizontal,
                  size: 17,
                  color: colors.primaryOnSoft,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.debtDetailUpdateBalance,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.primaryOnSoft,
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
