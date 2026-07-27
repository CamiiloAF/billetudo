import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/account_with_balance.dart';
import 'account_type_avatar.dart';

/// The `Account Card` component: one row of the accounts list.
///
/// Shows the account's balance, red only when it is actually negative — a
/// normal balance is never dressed as a problem (MASTER.md, tone of voice).
class AccountCard extends StatelessWidget {
  const AccountCard({required this.entry, this.onTap, super.key});

  final AccountWithBalance entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final account = entry.account;
    final balanceMinor = entry.balance.balanceMinor;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(16),
          // `start`, not `center`: the name wraps to up to two lines (bugfix
          // item 12), so the balance anchors to the top edge instead of
          // floating to the vertical middle of a two-line name. Short names
          // stay on one line — the uneven row height is accepted by design.
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AccountTypeAvatar(type: account.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      // 600, not 700: `Account Card`'s `Name` (`w4d4i6`) is
                      // 15/600 — only the balance is 700.
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
                const MoneyFormatter()
                    .formatSymbol(balanceMinor, currencyCode: account.currency),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: balanceMinor < 0 ? colors.expense : colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
