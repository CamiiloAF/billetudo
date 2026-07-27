import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/money_formatter.dart';

/// The confirmation sheet's Scope Note (`krYB5`): the one thing the user
/// cannot deduce by looking — editing here touches this occurrence only, and
/// the template will keep proposing its own amount next time.
class ScheduledScopeNote extends StatelessWidget {
  const ScheduledScopeNote({
    required this.templateAmountMinor,
    required this.currency,
    super.key,
  });

  /// The *template's* amount, not the (possibly edited) occurrence's one:
  /// the note's whole point is what the next occurrence will propose.
  final int templateAmountMinor;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    const money = MoneyFormatter();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.info, size: 14, color: colors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            l10n.scheduledConfirmationSheetScopeNote(
              money.formatSymbol(templateAmountMinor, currencyCode: currency),
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
