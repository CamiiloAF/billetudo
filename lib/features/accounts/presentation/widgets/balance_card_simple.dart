import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';

/// Balance Card of a non-card account (`ZCSCc`): one label, one figure.
class BalanceCardSimple extends StatelessWidget {
  const BalanceCardSimple({
    required this.balanceMinor,
    required this.currency,
    super.key,
  });

  final int balanceMinor;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context).accountBalanceLabel,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            const MoneyFormatter().format(balanceMinor, currencyCode: currency),
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: balanceMinor < 0 ? colors.expense : colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
