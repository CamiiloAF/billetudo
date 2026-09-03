import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/sheet_list_viewport.dart';
import '../../../../accounts/domain/entities/account_with_balance.dart';
import 'currency_group.dart';
import 'currency_group_section.dart';

/// "Tu dinero" (`bEYPr`/`D1L1cE`, `design-system/billetudo/pages/inicio.md`
/// § "Hoja de saldos"): every active account, grouped **only** by currency —
/// multi-currency totals never mix (Fase 0 does not normalise across
/// currencies) — opened from the header's wallet button, the only path left
/// to the balances view now that the "Mis cuentas" strip is gone from Home.
///
/// With no active account (`X7eBX`, "Vacío Variante A"), the list is
/// replaced by the same `Empty State` pattern Cuentas already uses
/// (`AccountsEmptyView`) — landmark icon, the exact same copy, and a CTA that
/// closes this sheet before pushing the new-account form, matching how a row
/// tap already closes the sheet before opening Movimientos (`GH-24`).
class BalancesSheet extends StatelessWidget {
  const BalancesSheet({
    required this.accounts,
    this.onOpenAccountMovements,
    this.onAddAccount,
    super.key,
  });

  final List<AccountWithBalance> accounts;

  /// Criterion 4: tapping a row opens Movimientos filtered to that account —
  /// never an account detail page.
  final ValueChanged<String>? onOpenAccountMovements;

  /// The empty state's CTA. Called after this sheet has already closed
  /// itself, same as [onOpenAccountMovements].
  final VoidCallback? onAddAccount;

  static Future<void> show(
    BuildContext context, {
    required List<AccountWithBalance> accounts,
    ValueChanged<String>? onOpenAccountMovements,
    VoidCallback? onAddAccount,
  }) =>
      BottomSheetBase.show<void>(
        context,
        builder: (context) => BalancesSheet(
          accounts: accounts,
          onOpenAccountMovements: onOpenAccountMovements,
          onAddAccount: onAddAccount,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final groups = CurrencyGroup.from(accounts);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeBalancesSheetTitle,
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        if (groups.isEmpty)
          EmptyState(
            icon: LucideIcons.landmark,
            message: l10n.accountsEmptyMessage,
            ctaLabel: l10n.accountsAdd,
            onCta: () {
              Navigator.of(context).pop();
              onAddAccount?.call();
            },
          )
        else
          SheetListViewport(
            height: 480,
            child: ListView.separated(
              itemCount: groups.length,
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              itemBuilder: (context, index) => CurrencyGroupSection(
                group: groups[index],
                onOpenAccountMovements: onOpenAccountMovements,
              ),
            ),
          ),
      ],
    );
  }
}
