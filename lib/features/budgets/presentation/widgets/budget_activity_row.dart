import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../categories/presentation/utils/category_appearance.dart';
import '../../domain/entities/budget_activity_item.dart';

/// One row of a budget's period activity (HU-04). Structurally the shared
/// `Transaction Row` (`DKJaf`) as the detail instances it: a 44pt icon-wrap in
/// the category's soft tone, "Cuenta · Fecha" underneath the title, and the
/// amount on the right — no card, no border. The rows sit straight on
/// `$background` inside the activity section (`NloPT/Abx0H`).
///
/// Tappable, same as `Transaction Row`: opens the real transaction's detail.
///
/// [BudgetActivityItem.isNettedTransfer] draws a fixed override instead of
/// the usual category appearance (`l3si5`/`HEgoB`, "Fila especial —
/// Transferencia interna neteada"): icon-wrap `$primary-soft` +
/// `arrow-left-right` in `$primary-on-soft`, title "Transferencia interna",
/// subtitle "‹origen› ↔ ‹destino› · ‹fecha›" and `$0` in `$text-secondary` —
/// never the green/red family, since the movement cancels itself out for
/// this budget.
class BudgetActivityRow extends StatelessWidget {
  const BudgetActivityRow({
    required this.item,
    required this.onTap,
    super.key,
  });

  final BudgetActivityItem item;

  /// Called with [item]'s id (the real `Transaction` id) to open its detail.
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isNetted = item.isNettedTransfer;

    return InkWell(
      onTap: () => onTap(item.id),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isNetted
                  ? colors.primarySoft
                  : CategoryAppearance.softColorFor(colors, item.categoryColor),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isNetted
                  ? LucideIcons.arrowLeftRight
                  : CategoryAppearance.iconFor(item.categoryIcon),
              size: 20,
              color: isNetted
                  ? colors.primaryOnSoft
                  : CategoryAppearance.colorFor(colors, item.categoryColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isNetted ? l10n.budgetActivityNettedTransferTitle : item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle(),
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
            _amountLabel(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isNetted ? colors.textSecondary : colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Signed, and in `$text-primary` (not red/green) — the deliberate exception
  /// to the app-wide rule that an expense renders unsigned. In the
  /// Transactions list a row can be income, expense or transfer, so the sign
  /// would be noise; here every row sits under an accumulated total for the
  /// *same* budget, and the sign is what marks whether it subtracted from or
  /// added to the period's disponible rather than showing a running balance.
  /// Verified node by node against `NloPT/U6y9n/a1Pwa`, `rmROV`, `oD0A1`,
  /// `p4qBp` and their twins in `DN0GV` and `QLn6w`: all 12 read `-$X` in
  /// `$text-primary` — every one of those is a plain expense/transfer row, the
  /// only kind the frames model. `+$X` for [BudgetActivityItem.isIncome]
  /// (budget-income-counts-in-budget, e.g. a debt repayment received) has no
  /// Pencil frame yet; it follows the same `$text-primary`, unsigned-by-color
  /// convention, only flipping the sign character to match the calculator's
  /// own subtraction in `BudgetProgressCalculator.spentIn`. Do not "fix"
  /// either sign back to unsigned. A netted transfer row is the one
  /// exception to "signed": it always reads unsigned `$0`, in
  /// `$text-secondary` (verified against `l3si5/HEgoB/a1Pwa`) — it is neither
  /// an expense nor an income for this budget.
  String _amountLabel() {
    if (item.isNettedTransfer) {
      return const MoneyFormatter()
          .formatSymbol(0, currencyCode: item.currency);
    }
    final amount = const MoneyFormatter()
        .formatSymbol(item.amountMinor, currencyCode: item.currency);
    return item.isIncome ? '+$amount' : '-$amount';
  }

  /// "Cuenta · Fecha" (`DKJaf/pjX7P`); the note tags along when there is one so
  /// it is not lost from the list. A netted transfer reads
  /// "‹origen› ↔ ‹destino› · ‹fecha›" instead (`l3si5/HEgoB/pjX7P`), never a
  /// note — the row already represents two accounts, not one movement.
  String _subtitle() {
    final date = DateFormat.yMMMd('es_CO').format(item.date);
    if (item.isNettedTransfer) {
      return '${item.accountName} ↔ ${item.secondaryAccountName} · $date';
    }
    final base = '${item.accountName} · $date';
    final note = item.note;
    return note == null || note.isEmpty ? base : '$base · $note';
  }
}
