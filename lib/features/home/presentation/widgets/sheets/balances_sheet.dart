import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_list_viewport.dart';
import '../../../../accounts/domain/entities/account_with_balance.dart';
import 'currency_group.dart';
import 'currency_group_section.dart';

/// "Tu dinero" (`bEYPr`/`D1L1cE`, `design-system/billetudo/pages/inicio.md`
/// § "Hoja de saldos"): every active account, grouped **only** by currency —
/// multi-currency totals never mix (Fase 0 does not normalise across
/// currencies) — opened from the header's wallet button, the only path left
/// to the balances view now that the "Mis cuentas" strip is gone from Home.
class BalancesSheet extends StatelessWidget {
  const BalancesSheet({
    required this.accounts,
    this.onOpenAccountMovements,
    super.key,
  });

  final List<AccountWithBalance> accounts;

  /// Criterion 4: tapping a row opens Movimientos filtered to that account —
  /// never an account detail page.
  final ValueChanged<String>? onOpenAccountMovements;

  static Future<void> show(
    BuildContext context, {
    required List<AccountWithBalance> accounts,
    ValueChanged<String>? onOpenAccountMovements,
  }) =>
      BottomSheetBase.show<void>(
        context,
        builder: (context) => BalancesSheet(
          accounts: accounts,
          onOpenAccountMovements: onOpenAccountMovements,
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
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
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
