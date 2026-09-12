import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../domain/entities/quick_access_item.dart';
import 'quick_access_chip_with_badge.dart';
import 'quick_access_row.dart' show QuickAccessChip, QuickAccessRow;

/// One chip inside [QuickAccessRow]'s horizontal scroll: resolves [item]'s
/// icon, label and destination, and renders either the badge variant
/// ([QuickAccessChipWithBadge], for "Pagos programados" with pending
/// occurrences) or the plain [QuickAccessChip] otherwise.
class QuickAccessRowChip extends StatelessWidget {
  const QuickAccessRowChip({
    required this.item,
    required this.pendingScheduledCount,
    required this.onOpenScheduledPayments,
    required this.onOpenAccounts,
    required this.onOpenDebts,
    required this.onOpenReports,
    required this.onOpenGoals,
    super.key,
  });

  final QuickAccessItem item;

  /// Scheduled-payment occurrences pending confirmation — see
  /// [QuickAccessRow.pendingScheduledCount].
  final int pendingScheduledCount;

  final VoidCallback onOpenScheduledPayments;
  final VoidCallback onOpenAccounts;
  final VoidCallback onOpenDebts;
  final VoidCallback onOpenReports;
  final VoidCallback onOpenGoals;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (item == QuickAccessItem.scheduledPayments &&
        pendingScheduledCount > 0) {
      return QuickAccessChipWithBadge(
        icon: LucideIcons.calendarClock,
        label: l10n.homeQuickAccessScheduledPayments,
        count: pendingScheduledCount,
        onTap: onOpenScheduledPayments,
      );
    }
    return QuickAccessChip(
      icon: _iconFor(item),
      label: _labelFor(l10n, item),
      onTap: _onTapFor(item),
    );
  }

  IconData _iconFor(QuickAccessItem item) => switch (item) {
        QuickAccessItem.scheduledPayments => LucideIcons.calendarClock,
        QuickAccessItem.accounts => LucideIcons.wallet,
        QuickAccessItem.debts => LucideIcons.handCoins,
        QuickAccessItem.reports => LucideIcons.chartColumn,
        QuickAccessItem.goals => LucideIcons.target,
      };

  String _labelFor(AppLocalizations l10n, QuickAccessItem item) =>
      switch (item) {
        QuickAccessItem.scheduledPayments =>
          l10n.homeQuickAccessScheduledPayments,
        QuickAccessItem.accounts => l10n.accountsTitle,
        QuickAccessItem.debts => l10n.moreDebts,
        QuickAccessItem.reports => l10n.moreReports,
        QuickAccessItem.goals => l10n.navGoals,
      };

  VoidCallback _onTapFor(QuickAccessItem item) => switch (item) {
        QuickAccessItem.scheduledPayments => onOpenScheduledPayments,
        QuickAccessItem.accounts => onOpenAccounts,
        QuickAccessItem.debts => onOpenDebts,
        QuickAccessItem.reports => onOpenReports,
        QuickAccessItem.goals => onOpenGoals,
      };
}
