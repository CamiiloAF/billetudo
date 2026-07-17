import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/account_balance.dart';
import 'account_type_avatar.dart';

/// A single-select account row (`Filter Account Row`, `X3tZG`): the account's
/// type avatar, its name over its type, and its balance on the right. A tap
/// picks it ([onTap]).
///
/// [selected] switches the row to the `primary-soft` fill with a `primary`
/// stroke and reveals the trailing check — used by any account picker that
/// wants to mark the current choice.
class AccountSelectRow extends StatelessWidget {
  const AccountSelectRow({
    required this.account,
    required this.balance,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Account account;
  final AccountBalance balance;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final balanceMinor = balance.balanceMinor;
    final isNegative = balanceMinor < 0;

    return Material(
      color: selected ? colors.primarySoft : colors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                AccountTypeAvatar(type: account.type),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        account.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        account.type.label(l10n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  const MoneyFormatter().formatSymbol(
                    balanceMinor,
                    currencyCode: account.currency,
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isNegative ? colors.expenseText : colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: selected
                      ? Icon(
                          LucideIcons.check,
                          size: 18,
                          color: colors.primary,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
