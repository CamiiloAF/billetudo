import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/money_formatter.dart';
import 'net_worth_hero_figure.dart';

/// The `Hero Patrimonio` figures (`kgM3u/AG8Bb`): líquido and total, side by
/// side. **No Label Row** here — the "Regla del Label Row"
/// (`design-system/billetudo/pages/graficas.md`) reserves it for a hero with
/// a single protagonist figure; with two figures each brings its own label.
class NetWorthHero extends StatelessWidget {
  const NetWorthHero({
    required this.liquidMinor,
    required this.totalMinor,
    this.currencyCode = 'COP',
    super.key,
  });

  final int liquidMinor;
  final int totalMinor;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    const money = MoneyFormatter();

    return Semantics(
      label:
          '${l10n.reportsNetWorthFigureLiquidLabel}: '
          '${money.formatSymbol(liquidMinor, currencyCode: currencyCode)}. '
          '${l10n.reportsNetWorthFigureTotalLabel}: '
          '${money.formatSymbol(totalMinor, currencyCode: currencyCode)}.',
      container: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            NetWorthHeroFigure(
              label: l10n.reportsNetWorthFigureLiquidLabel,
              amountMinor: liquidMinor,
              currencyCode: currencyCode,
            ),
            const SizedBox(width: 12),
            NetWorthHeroFigure(
              label: l10n.reportsNetWorthFigureTotalLabel,
              amountMinor: totalMinor,
              currencyCode: currencyCode,
            ),
          ],
        ),
      ),
    );
  }
}
