import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../cubit/account_form_state.dart';
import '../bottom_sheet_base.dart';
import '../currency_row.dart';

/// Picks the account's currency.
///
/// Only COP and USD for now (MXN/EUR were dropped). Tap picks and closes: with
/// a handful of options an explicit "Confirmar" is a step that buys nothing.
class CurrencyPickerSheet extends StatelessWidget {
  const CurrencyPickerSheet({required this.selected, super.key});

  final String selected;

  /// Resolves to the chosen ISO-4217 code, or null if dismissed.
  static Future<String?> show(
    BuildContext context, {
    required String selected,
  }) =>
      BottomSheetBase.show<String>(
        context,
        builder: (context) => CurrencyPickerSheet(selected: selected),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.accountCurrencySheetTitle,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        for (final code in AccountFormState.supportedCurrencies)
          CurrencyRow(
            code: code,
            name: _nameOf(code, l10n),
            isSelected: code == selected,
            onTap: () => Navigator.of(context).pop(code),
          ),
      ],
    );
  }

  String _nameOf(String code, AppLocalizations l10n) =>
      code == 'USD' ? l10n.currencyUsdName : l10n.currencyCopName;
}
