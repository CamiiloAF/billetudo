import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import 'balance_edit_button.dart';

/// Balance Card of a non-card account (`ZCSCc`): one label, one figure, and the
/// subtle "Ajustar saldo" pencil to the right of the figure (Mejora #1).
class BalanceCardSimple extends StatelessWidget {
  const BalanceCardSimple({
    required this.balanceMinor,
    required this.currency,
    this.onEditBalance,
    super.key,
  });

  final int balanceMinor;
  final String currency;

  /// Opens "Ajustar saldo" when set. `null` hides the pencil.
  final VoidCallback? onEditBalance;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).accountBalanceLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                child: Text(
                  const MoneyFormatter()
                      .formatSymbol(balanceMinor, currencyCode: currency),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color:
                        balanceMinor < 0 ? colors.expense : colors.textPrimary,
                  ),
                ),
              ),
              if (onEditBalance != null) ...[
                const SizedBox(width: 4),
                BalanceEditButton(onPressed: onEditBalance!),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
