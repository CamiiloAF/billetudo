import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import 'balance_mini_card.dart';

/// The Home "Mis cuentas" balance strip (`e0maL`, bugfix item 8): a captioned
/// header with a "Ver todas" link, over a horizontally scrolling row of
/// per-account [BalanceMiniCard]s. No total is shown — Phase 0 does not
/// normalise across currencies, so summing would be misleading.
///
/// Renders nothing when there are no accounts, so the Home's empty/first-run
/// state stays clean.
class HomeBalancesStrip extends StatelessWidget {
  const HomeBalancesStrip({
    required this.accounts,
    required this.onSeeAll,
    this.onOpenAccountMovements,
    super.key,
  });

  final List<AccountWithBalance> accounts;

  /// Navigates to the full Cuentas list.
  final VoidCallback onSeeAll;

  /// Bugfix item 8: opens Movimientos filtered to the tapped account, if wired.
  final ValueChanged<String>? onOpenAccountMovements;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: BalancesStripHeader(onSeeAll: onSeeAll),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              for (var i = 0; i < accounts.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                BalanceMiniCard(
                  entry: accounts[i],
                  onTap: onOpenAccountMovements == null
                      ? null
                      : () => onOpenAccountMovements!(accounts[i].account.id),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The strip's header row: the "Mis cuentas" caption and the "Ver todas →"
/// link that opens the full Cuentas list.
class BalancesStripHeader extends StatelessWidget {
  const BalancesStripHeader({required this.onSeeAll, super.key});

  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.homeBalancesTitle,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ),
        InkWell(
          onTap: onSeeAll,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.homeBalancesSeeAll,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 12,
                    color: colors.primaryOnSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(LucideIcons.arrowRight,
                    size: 14, color: colors.primaryOnSoft),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
