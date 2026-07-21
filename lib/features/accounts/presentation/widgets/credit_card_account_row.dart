import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/account_with_balance.dart';
import 'account_type_avatar.dart';
import 'credit_usage_bar.dart';

/// The `Credit Card Account Row` component: a credit card in the accounts list.
///
/// A card earns a taller row than `AccountCard` because debt alone does not
/// answer the question the user actually has — how much is left to spend.
class CreditCardAccountRow extends StatelessWidget {
  const CreditCardAccountRow({required this.entry, this.onTap, super.key});

  final AccountWithBalance entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final account = entry.account;
    final balance = entry.balance;
    const money = MoneyFormatter();
    final creditLimitMinor = account.creditLimitMinor;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AccountTypeAvatar(type: account.type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          // 600, not 700: `Credit Card Account Row`'s `Name`
                          // (`Z4mwDi`) is 15/600 — only `Debt` is 700.
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          account.type.label(l10n),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    money.formatSymbol(
                      balance.balanceMinor,
                      currencyCode: account.currency,
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: balance.balanceMinor < 0
                          ? colors.expense
                          : colors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (creditLimitMinor != null) ...[
                const SizedBox(height: 14),
                CreditUsageBar(
                  balance: balance,
                  creditLimitMinor: creditLimitMinor,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.accountDebtShortLabel,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.textSecondary),
                    ),
                    Text(
                      l10n.accountAvailableCreditLabel,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      money.formatSymbol(
                        balance.debtMinor,
                        currencyCode: account.currency,
                      ),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      money.formatSymbol(
                        // Floored at 0 by the domain: available credit is never
                        // shown negative (HU-02).
                        balance.availableCreditMinor ?? 0,
                        currencyCode: account.currency,
                      ),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
