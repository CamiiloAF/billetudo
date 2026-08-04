import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_head.dart';
import '../goal_currency_row.dart';

/// Picks the goal's currency (HU-01), only offered while the goal has no
/// linked account — once one is set, HU-02 locks the currency to it and this
/// sheet is never opened.
class GoalCurrencyPickerSheet extends StatelessWidget {
  const GoalCurrencyPickerSheet({required this.selected, super.key});

  static const List<String> supportedCurrencies = ['COP', 'USD'];

  final String selected;

  /// Resolves to the chosen ISO-4217 code, or null if dismissed.
  static Future<String?> show(BuildContext context, {required String selected}) =>
      BottomSheetBase.show<String>(
        context,
        builder: (context) => GoalCurrencyPickerSheet(selected: selected),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SheetHead(title: l10n.goalCurrencySheetTitle),
        const SizedBox(height: 12),
        for (final code in supportedCurrencies) ...[
          GoalCurrencyRow(
            code: code,
            name: code == 'USD' ? l10n.currencyUsdName : l10n.currencyCopName,
            selected: code == selected,
            onTap: () => Navigator.of(context).pop(code),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
