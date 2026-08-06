import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import 'mini_type_icon.dart';

/// One card of the Home "Mis cuentas" strip (`EVe8a`, bugfix item 8): the
/// account's type icon+colour, its name and its balance. Fixed 158-wide so the
/// row scrolls horizontally; the name truncates rather than wrapping.
///
/// The balance turns red only when it is actually negative — the same tone rule
/// as `AccountCard`; a normal balance is never dressed as a problem (MASTER.md).
class BalanceMiniCard extends StatelessWidget {
  const BalanceMiniCard({required this.entry, this.onTap, super.key});

  final AccountWithBalance entry;
  final VoidCallback? onTap;

  /// The frame's fixed card width (`EVe8a`).
  static const double width = 158;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final account = entry.account;
    final balanceMinor = entry.balance.balanceMinor;

    return SizedBox(
      width: width,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    MiniTypeIcon(type: account.type),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        account.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  const MoneyFormatter().formatSymbol(
                    balanceMinor,
                    currencyCode: account.currency,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color:
                        balanceMinor < 0 ? colors.expense : colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
