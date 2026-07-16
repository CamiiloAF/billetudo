import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// The "Sobrecupo" badge.
///
/// Icon and text use `$expense-text`, not `$expense`: at this size plain
/// `$expense` does not reach 4.5:1 against `$expense-soft` in either theme
/// (MASTER.md).
class OverLimitBadge extends StatelessWidget {
  const OverLimitBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.expenseSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.triangleAlert,
            size: 14,
            color: colors.expenseText,
          ),
          const SizedBox(width: 4),
          Text(
            l10n.accountOverLimitBadge,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.expenseText,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
