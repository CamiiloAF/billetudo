import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/accounts_overview.dart';

/// The Total Card: net worth on the `$primary-deep`→`$primary` gradient, with
/// the debt sub-line that tells assets from liabilities without grouping the
/// list.
///
/// With one currency it shows a single total. With several it shows **one
/// subtotal per currency** and never a cross-currency sum — adding COP to USD
/// would be an invented number. The rule itself lives in [AccountsOverview].
class AccountsTotalCard extends StatelessWidget {
  const AccountsTotalCard({required this.overview, super.key});

  final AccountsOverview overview;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Never `primary-light` behind text: it fails contrast (MASTER.md).
        gradient: LinearGradient(
          colors: [colors.primaryDeep, colors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).accountsTotalLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          for (final subtotal in overview.subtotals)
            CurrencySubtotalLine(
              subtotal: subtotal,
              // One currency reads as "the" total, so it takes the hero size.
              isSingle: overview.isSingleCurrency,
            ),
        ],
      ),
    );
  }
}

/// Net worth (and debt, when there is any) of a single currency.
class CurrencySubtotalLine extends StatelessWidget {
  const CurrencySubtotalLine({
    required this.subtotal,
    required this.isSingle,
    super.key,
  });

  final CurrencySubtotal subtotal;
  final bool isSingle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    const money = MoneyFormatter();

    return Padding(
      padding: EdgeInsets.only(bottom: isSingle ? 0 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            money.formatSymbol(
              subtotal.netWorthMinor,
              currencyCode: subtotal.currency,
            ),
            style: (isSingle
                    ? theme.textTheme.headlineLarge
                    : theme.textTheme.headlineSmall)
                ?.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtotal.hasDebt) ...[
            const SizedBox(height: 4),
            Text(
              l10n.accountsTotalDebtsLine(
                money.formatSymbol(
                  subtotal.debtMinor,
                  currencyCode: subtotal.currency,
                ),
              ),
              style: theme.textTheme.labelMedium?.copyWith(
                // Solid `on-primary`, never a translucent white: hierarchy
                // comes from size/weight (MASTER.md accessibility rule 2).
                color: colors.onPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
