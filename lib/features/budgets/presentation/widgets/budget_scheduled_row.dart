import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../categories/presentation/utils/category_appearance.dart';
import '../../domain/entities/budget_scheduled_item.dart';

/// One row of a budget's "programado" list (HU-12): mirror of
/// `BudgetActivityRow`, but for a scheduled-payment occurrence that has not
/// materialized as a `Transaction` yet — so, unlike the activity row, the
/// amount renders unsigned (same convention Pagos Programados settled on for
/// its own expense rows: only income carries a sign).
///
/// Tappable: opens the template's detail (`item.scheduledPaymentId`), not the
/// synthetic occurrence id.
class BudgetScheduledRow extends StatelessWidget {
  const BudgetScheduledRow({
    required this.item,
    required this.onTap,
    super.key,
  });

  final BudgetScheduledItem item;

  /// Called with [item]'s `scheduledPaymentId` (the template's id) to open
  /// its detail.
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return InkWell(
      onTap: () => onTap(item.scheduledPaymentId),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: CategoryAppearance.softColorFor(
                      colors,
                      item.categoryColor,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    CategoryAppearance.iconFor(item.categoryIcon),
                    size: 20,
                    color: CategoryAppearance.colorFor(
                      colors,
                      item.categoryColor,
                    ),
                  ),
                ),
                Positioned(
                  left: 28,
                  top: 28,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.border),
                    ),
                    child: Icon(
                      LucideIcons.repeat,
                      size: 9,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle(l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            const MoneyFormatter()
                .formatSymbol(item.amountMinor, currencyCode: item.currency),
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// "Próximo: Fecha · Cuenta", with the date of *this* occurrence — a weekly
  /// template can show up more than once in a monthly window, each with its
  /// own date.
  String _subtitle(AppLocalizations l10n) {
    final date = DateFormat.yMMMd('es_CO').format(item.date);
    return l10n.budgetScheduledRowSubtitle(date, item.accountName);
  }
}
