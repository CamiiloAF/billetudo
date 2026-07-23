import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../accounts/presentation/widgets/account_type_avatar.dart';

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
                    _MiniTypeIcon(type: account.type),
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

/// The mini card's 30×30 rounded-square type glyph (`r8QG5`): smaller and
/// squarer than the list's circular `AccountTypeAvatar`, but the same
/// icon+colour mapping via [AccountTypePresentation].
class _MiniTypeIcon extends StatelessWidget {
  const _MiniTypeIcon({required this.type});

  final AccountType type;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: type.softColor(colors),
        // `r8QG5` is a rounded square at radius 10 — smaller than any shared
        // token, so it stays a literal here.
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(type.icon, color: type.color(colors), size: 16),
    );
  }
}
