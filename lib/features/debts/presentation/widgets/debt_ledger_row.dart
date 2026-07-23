import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/debt_ledger_entry.dart';
import '../utils/debt_format.dart';

/// One row of the unified debt history (`JAmxJ`), with its running balance.
///
/// Distinguishes a **cash** event (a `Transaction`: `$primary-soft` icon-wrap,
/// `$text-primary` amount) from a **solo-deuda** entry (`$muted` icon-wrap,
/// `$text-secondary` amount + a tag) — the sign of the amount is already
/// resolved by the domain, never re-derived here.
class DebtLedgerRow extends StatelessWidget {
  const DebtLedgerRow({
    required this.entry,
    required this.direction,
    required this.runningMinor,
    required this.currency,
    this.onOpenTransaction,
    super.key,
  });

  final DebtLedgerEntry entry;
  final DebtDirection direction;
  final int runningMinor;
  final String currency;

  /// Opens the underlying `Transaction`'s detail (HU-04). Only cash rows carry
  /// a `transactionId`; solo-deuda rows (interest/adjustment) are not tappable.
  final ValueChanged<String>? onOpenTransaction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isCash = entry.isCashEvent;
    final tag = DebtFormat.ledgerTag(l10n, entry);
    final note = entry.note;
    final meta = note != null && note.isNotEmpty
        ? '${DebtFormat.dateShort(context, entry.date)} · $note'
        : DebtFormat.dateShort(context, entry.date);

    // A cash row deep-links into its movement's detail; a solo-deuda row has no
    // movement behind it, so it stays inert.
    final transactionId = entry.transactionId;
    final onOpenTransaction = this.onOpenTransaction;
    final onTap = isCash && transactionId != null && onOpenTransaction != null
        ? () => onOpenTransaction(transactionId)
        : null;

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isCash ? colors.primarySoft : colors.muted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              DebtFormat.ledgerIcon(entry.kind),
              size: 20,
              color: isCash ? colors.primaryOnSoft : colors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DebtFormat.ledgerTitle(l10n, entry, direction),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    if (tag != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.muted,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DebtFormat.signedAmount(entry.effectMinor, currency),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isCash ? colors.textPrimary : colors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.debtLedgerRunning(
                  DebtFormat.amount(runningMinor, currency),
                ),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) {
      return row;
    }
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: row,
      ),
    );
  }
}
