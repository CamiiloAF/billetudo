import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_head.dart';
import '../../../../accounts/domain/entities/account_with_balance.dart';
import '../../../../accounts/presentation/widgets/account_select_row.dart';

/// HU-02: single-select account picker for the crear/editar meta form.
/// Reuses the accounts feature's `Filter Account Row` (`X3tZG`), same
/// precedent as `DebtAccountPickerSheet`.
class GoalAccountPickerSheet extends StatelessWidget {
  const GoalAccountPickerSheet({
    required this.accounts,
    required this.selectedId,
    super.key,
  });

  final List<AccountWithBalance> accounts;
  final String? selectedId;

  /// Resolves to the chosen account, or null if dismissed.
  static Future<AccountWithBalance?> show(
    BuildContext context, {
    required List<AccountWithBalance> accounts,
    required String? selectedId,
  }) =>
      BottomSheetBase.show<AccountWithBalance>(
        context,
        builder: (context) => GoalAccountPickerSheet(
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
        SheetHead(title: l10n.goalFormAccountPickerTitle),
        const SizedBox(height: 12),
        for (final entry in accounts) ...[
          AccountSelectRow(
            account: entry.account,
            balance: entry.balance,
            selected: entry.account.id == selectedId,
            onTap: () => Navigator.of(context).pop(entry),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
