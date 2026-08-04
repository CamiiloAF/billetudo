import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/transaction.dart';

/// Turns Movimientos into "link mode" (`g0x859`, Deudas HU-02; reused for
/// Metas' "Enlazar un movimiento", HU-03): the same list, but with a banner
/// naming the target (a debt or a goal), the FAB hidden, and every row tap
/// attributing that movement to it instead of opening its detail.
///
/// A plain value object so `TransactionsPage` stays decoupled from both the
/// Deudas and Metas features — each router builds this with callbacks wired
/// to its own link cubit, and the page only reads it.
@immutable
class TransactionsLinkMode {
  const TransactionsLinkMode({
    required this.bannerTitle,
    required this.bannerBody,
    required this.onCancel,
    required this.onLinkTransaction,
    this.requiredType,
    this.notBefore,
  });

  /// Already localized banner title, e.g. "Enlazar a Crédito vehicular" or
  /// "Enlazar a Viaje a Cartagena".
  final String bannerTitle;

  /// Already localized banner body, e.g. "Elige un movimiento que ya
  /// registraste; lo atribuimos a esta deuda/meta, no creamos uno nuevo."
  final String bannerBody;

  /// Cancels link mode (the header back button).
  final VoidCallback onCancel;

  /// Attributes the tapped transaction to the debt/goal and returns once done.
  final Future<void> Function(String transactionId) onLinkTransaction;

  /// Restricts which movement types may be linked. `null` means any type is
  /// eligible (e.g. Metas, HU-03: any registered movement can be attributed
  /// to a goal). Deudas (HU-02) sets this to the cash-event type the debt's
  /// direction implies ("Yo debo" → `expense`, "Me deben" → `income`) — a
  /// movement of any other type would push the debt's balance the wrong way.
  final TransactionType? requiredType;

  /// Movements dated before this cannot be linked — the debt/goal did not
  /// exist yet. `null` means no lower bound (Metas imposes none).
  final DateTime? notBefore;

  /// Whether [transaction] is eligible to be linked: it must match
  /// [requiredType] (when set), not already carry a debt or a goal (#4 — a
  /// movement already attributed to one must not be re-linked to another),
  /// and not predate [notBefore] (compared by calendar day, so a same-day
  /// movement with an earlier time still qualifies).
  bool accepts(Transaction transaction) {
    if (requiredType != null && transaction.type != requiredType) {
      return false;
    }
    // #4: a movement already attributed to a debt or a goal is not
    // selectable and never shows in link mode.
    if (transaction.debtId != null || transaction.goalId != null) {
      return false;
    }
    final floor = notBefore;
    if (floor == null) {
      return true;
    }
    final day = DateTime(
      transaction.date.year,
      transaction.date.month,
      transaction.date.day,
    );
    return !day.isBefore(DateTime(floor.year, floor.month, floor.day));
  }
}

/// The `$primary-soft` banner (`Y71NB`) shown at the top of the list in link
/// mode: a `link-2` glyph and the "Enlazar a …" prompt. Cancelling is the
/// header back button, so the banner carries no "x".
class TransactionsLinkBanner extends StatelessWidget {
  const TransactionsLinkBanner({required this.linkMode, super.key});

  final TransactionsLinkMode linkMode;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: colors.primarySoft,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                LucideIcons.link2,
                size: 18,
                color: colors.primaryOnSoftStrong,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    linkMode.bannerTitle,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.primaryOnSoftStrong,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    linkMode.bannerBody,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.hintText,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
