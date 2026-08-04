import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../domain/entities/account.dart';
import '../account_type_row.dart';

/// Picks an [AccountType] from a plain list, one tap to choose and close —
/// same interaction as `CurrencyPickerSheet`.
///
/// Cuentas' own add/edit form (`account_form_page.dart`) uses the inline
/// `AccountTypeGrid` instead: there, the type is the form's headline decision
/// (`CwiKu`, shown outright). Onboarding's "Tu primera cuenta" (`G7vDVK`)
/// deliberately renders "Tipo de cuenta" as a plain `Form Field` selector
/// like Nombre/Moneda/Saldo — `pages/onboarding.md`, "Tipo de cuenta como
/// campo de formulario, no como chip 'ya asentado'" — so it reads as one more
/// editable suggestion, not a decision the app already made for the user.
/// This sheet is that selector's picker.
class AccountTypePickerSheet extends StatelessWidget {
  const AccountTypePickerSheet({required this.selected, super.key});

  final AccountType? selected;

  /// Resolves to the chosen [AccountType], or null if dismissed.
  static Future<AccountType?> show(
    BuildContext context, {
    required AccountType? selected,
  }) =>
      BottomSheetBase.show<AccountType>(
        context,
        builder: (context) => AccountTypePickerSheet(selected: selected),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.accountTypeSheetTitle,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        for (final type in AccountType.values)
          AccountTypeRow(
            type: type,
            isSelected: type == selected,
            onTap: () => Navigator.of(context).pop(type),
          ),
      ],
    );
  }
}
