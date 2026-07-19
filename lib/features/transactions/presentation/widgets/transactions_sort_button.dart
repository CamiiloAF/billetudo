import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/transaction_filter.dart';

/// The Search Row's sort button (`B3GGa`/`xAk6Y`): toggles
/// [TransactionFilter.sortOrder] between the two orders the repository
/// already knows how to apply (HU-06).
class TransactionsSortButton extends StatelessWidget {
  const TransactionsSortButton({
    required this.sortOrder,
    required this.onTap,
    super.key,
  });

  final TransactionSortOrder sortOrder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final tooltip = switch (sortOrder) {
      TransactionSortOrder.dateDesc => l10n.transactionsSortDateDesc,
      TransactionSortOrder.amountDesc => l10n.transactionsSortAmountDesc,
    };

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 44,
            height: 48,
            child: Icon(
              LucideIcons.arrowUpDown,
              size: 20,
              color: colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
