import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_head.dart';
import '../../../../accounts/domain/entities/account_with_balance.dart';
import '../../../../accounts/presentation/widgets/account_select_row.dart';

/// Single-select account picker for the abono sheet (toggle "Sí"). Reuses the
/// accounts feature's `Filter Account Row` (`X3tZG`) so a debt cash event picks
/// its account with exactly the same row the rest of the app does.
class DebtAccountPickerSheet extends StatelessWidget {
  const DebtAccountPickerSheet({
    required this.accounts,
    required this.selectedId,
    super.key,
  });

  final List<AccountWithBalance> accounts;
  final String? selectedId;

  /// Opens the picker and resolves to the chosen account id, or null if
  /// dismissed.
  static Future<String?> show(
    BuildContext context, {
    required List<AccountWithBalance> accounts,
    required String? selectedId,
  }) =>
      BottomSheetBase.show<String>(
        context,
        builder: (context) => DebtAccountPickerSheet(
          accounts: accounts,
          selectedId: selectedId,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SheetHead(title: l10n.debtPaymentAccountPickerTitle),
        const SizedBox(height: 12),
        for (final entry in accounts) ...[
          AccountSelectRow(
            account: entry.account,
            balance: entry.balance,
            selected: entry.account.id == selectedId,
            onTap: () => Navigator.of(context).pop(entry.account.id),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
