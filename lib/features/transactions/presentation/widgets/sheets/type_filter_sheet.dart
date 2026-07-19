import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../domain/entities/transaction.dart';

/// HU-06's type filter sheet: income/expense/transfer, multiple selection.
class TypeFilterSheet extends StatefulWidget {
  const TypeFilterSheet({required this.initialSelected, super.key});

  final Set<TransactionType> initialSelected;

  static Future<Set<TransactionType>?> show(
    BuildContext context, {
    required Set<TransactionType> initialSelected,
  }) =>
      BottomSheetBase.show<Set<TransactionType>>(
        context,
        builder: (context) => TypeFilterSheet(initialSelected: initialSelected),
      );

  @override
  State<TypeFilterSheet> createState() => _TypeFilterSheetState();
}

class _TypeFilterSheetState extends State<TypeFilterSheet> {
  final Set<TransactionType> _selected = {};

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = {
      TransactionType.expense: l10n.transactionTypeExpense,
      TransactionType.income: l10n.transactionTypeIncome,
      TransactionType.transfer: l10n.transactionTypeTransfer,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.typeFilterSheetTitle,
            style: Theme.of(context).textTheme.titleLarge),
        for (final type in TransactionType.values)
          CheckboxListTile(
            value: _selected.contains(type),
            onChanged: (_) => setState(() {
              if (!_selected.remove(type)) {
                _selected.add(type);
              }
            }),
            title: Text(labels[type]!),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(_selected),
            child: Text(l10n.commonApply),
          ),
        ),
      ],
    );
  }
}
