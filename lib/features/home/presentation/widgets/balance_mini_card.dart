import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import 'mini_type_icon.dart';

/// One account row of the "Tu dinero" balances sheet (`BalancesSheet`,
/// `design-system/billetudo/pages/inicio.md` § "Hoja de saldos"): the
/// account's type icon+colour, its **full, never-truncated** name and its
/// balance. No chevron — tapping opens Movimientos filtered to the account
/// (criterion 4), never a detail page, so there is nothing to "navigate
/// into" that a chevron would promise.
///
/// Formerly the Home "Mis cuentas" strip's fixed-width scrolling card
/// (`EVe8a`); the strip was removed from Home in the hero redesign (its
/// shortcut is now the header's wallet button → this sheet), so the widget
/// dropped its fixed width and horizontal-card chrome in favor of a
/// full-width tappable row (350×74 tap target in the design, comfortably
/// over the 44pt floor).
///
/// The balance turns red only when it is actually negative — the same tone
/// rule as `AccountCard`; a normal balance is never dressed as a problem
/// (MASTER.md).
class BalanceMiniCard extends StatelessWidget {
  const BalanceMiniCard({required this.entry, this.onTap, super.key});

  final AccountWithBalance entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final account = entry.account;
    final balanceMinor = entry.balance.balanceMinor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              MiniTypeIcon(type: account.type),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  account.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                const MoneyFormatter().formatSymbol(
                  balanceMinor,
                  currencyCode: account.currency,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color:
                      balanceMinor < 0 ? colors.expense : colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
