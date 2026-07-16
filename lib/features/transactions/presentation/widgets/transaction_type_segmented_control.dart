import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../domain/entities/transaction.dart';

/// Gasto/Ingreso/Transferencia selector on the transaction form
/// (HU-01/02/03).
class TransactionTypeSegmentedControl extends StatelessWidget {
  const TransactionTypeSegmentedControl({
    required this.type,
    required this.onChanged,
    super.key,
  });

  final TransactionType type;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SegmentedButton<TransactionType>(
      segments: [
        ButtonSegment(
          value: TransactionType.expense,
          label: Text(l10n.transactionTypeExpense),
        ),
        ButtonSegment(
          value: TransactionType.income,
          label: Text(l10n.transactionTypeIncome),
        ),
        ButtonSegment(
          value: TransactionType.transfer,
          label: Text(l10n.transactionTypeTransfer),
        ),
      ],
      selected: {type},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
