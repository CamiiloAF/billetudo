import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// The "enlazado a deuda" badge on HU-08's detail screen, shown when the
/// transaction carries a `debtId` (bug 3, Deudas): a `$primary-soft` row with
/// a `landmark` icon, same family as `ScheduledDebtChip` in Pagos programados
/// — so a transaction registered from a debt's abono/desembolso is never
/// indistinguishable from an ordinary movement that merely shares its
/// category.
///
/// Tappable when [onTap] is set: the router wires it into the linked debt's
/// own detail page (same decoupling pattern as `TransactionsLinkMode` —
/// this widget never navigates itself, it only fires the callback).
class TransactionDebtLinkBadge extends StatelessWidget {
  const TransactionDebtLinkBadge({
    required this.debtName,
    this.onTap,
    super.key,
  });

  final String debtName;

  /// Opens the linked debt's detail page. `null` keeps the badge inert (e.g.
  /// tests that only assert the read-only content).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.landmark,
            size: 16,
            color: colors.primaryOnSoftStrong,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.transactionDetailDebtLinkedLabel(debtName),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.primaryOnSoftStrong,
              ),
            ),
          ),
        ],
      ),
    );
    final tap = onTap;
    if (tap == null) {
      return content;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: content,
      ),
    );
  }
}
